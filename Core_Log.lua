-- GuildeaOrdo Log and Roster Snapshotting
local addon = GuildeaOrdo

local LOG_MAX = 15000        -- cap log size per guild to prevent unbounded growth
local SNAPSHOT_DEBOUNCE = 2 -- seconds; coalesce burst GUILD_ROSTER_UPDATE events
local LEAVE_GRACE_SECONDS = 5 * 60  -- reduced to 5 minutes for faster leave logging

local lastSnapshot         -- previous snapshot used for diffing
local pendingSnapshot      -- coalescing timer-active flag

-- =========================================================
-- Tiny scheduler via OnUpdate
-- =========================================================
local scheduler = CreateFrame("Frame")
local queue = {}
scheduler:SetScript("OnUpdate", function(self)
    if #queue == 0 then return end
    local now = GetTime()
    local i = 1
    while i <= #queue do
        if now >= queue[i].when then
            local fn = queue[i].fn
            table.remove(queue, i)
            pcall(fn)
        else
            i = i + 1
        end
    end
end)

function addon:delayCall(secs, fn)
    table.insert(queue, { when = GetTime() + secs, fn = fn })
end

-- =========================================================
-- Log
-- =========================================================
local function pushLog(guild, entry)
    table.insert(guild.log, entry)
    while #guild.log > LOG_MAX do
        table.remove(guild.log, 1)
    end
end

function addon:ClearLog()
    local g = self:GetCurrentGuild()
    if g then g.log = {} end
end

-- =========================================================
-- Roster snapshot + diff
-- =========================================================
local function snapshotRoster()
    local snap = {}
    local n = GetNumGuildMembers() or 0
    if n == 0 then return snap end
    for i = 1, n do
        local name, rank, rankIndex, level, _, zone, note, officerNote, online, _, classFile = GetGuildRosterInfo(i)
        if name and name ~= "" then
            snap[name] = {
                index       = i,
                rank        = rank or "",
                rankIndex   = rankIndex or 0,
                level       = level or 0,
                zone        = zone or "",
                note        = note or "",
                officerNote = officerNote or "",
                online      = online and true or false,
                classFile   = classFile or "",
            }
        end
    end
    return snap
end

local function diffSnapshots(old, new, guild)
    local now = time()
    local todayStr = date("%b %d %Y", now)

    guild.pendingLeaves = guild.pendingLeaves or {}

    for name, info in pairs(new) do
        if not old[name] then
            local m = guild.members[name]
            if guild.pendingLeaves[name] then
                guild.pendingLeaves[name] = nil
            else
                pushLog(guild, {
                    t = now, type = "JOIN", who = name,
                    details = ("Lvl %d %s"):format(info.level, info.rank),
                })
                if not m then
                    m = {}
                    guild.members[name] = m
                    m.joinDate = todayStr
                    m.joinDateExact = true
                end

                if CanEditOfficerNote and CanEditOfficerNote() then
                    local currentNote = info.officerNote or ""
                    local dateTag = (GuildeaOrdoDB.bracketLeft or "[") .. todayStr .. (GuildeaOrdoDB.bracketRight or "]")
                    local lMag = addon.escapePattern(GuildeaOrdoDB and GuildeaOrdoDB.bracketLeft or "[")
                    local rMag = addon.escapePattern(GuildeaOrdoDB and GuildeaOrdoDB.bracketRight or "]")
                    if not string.match(currentNote, lMag .. "%a%a%a %d%d %d%d%d%d" .. rMag) then                        local newNote = currentNote
                        if currentNote == "" then
                            newNote = dateTag
                        elseif string.len(currentNote) + string.len(dateTag) + 1 <= 30 then
                            newNote = currentNote .. " " .. dateTag
                        end
                        if newNote ~= currentNote and info.index then
                            GuildRosterSetOfficerNote(info.index, newNote)
                        end
                    end
                end
            end
        end
    end

    for name in pairs(old) do
        if not new[name] then
            if not guild.pendingLeaves[name] then
                guild.pendingLeaves[name] = now
                addon:delayCall(LEAVE_GRACE_SECONDS + 2, function()
                    if IsInGuild() then GuildRoster() end
                end)
            end
        end
    end

    for name, n in pairs(new) do
        local o = old[name]
        if o then
            if o.rank ~= n.rank then
                local kind = ((o.rankIndex or 0) > (n.rankIndex or 0)) and "PROMOTE" or "DEMOTE"
                pushLog(guild, {
                    t = now, type = kind, who = name,
                    details = ("%s -> %s"):format(o.rank, n.rank),
                })
            end
            if o.note ~= n.note then
                pushLog(guild, {
                    t = now, type = "NOTE", who = name,
                    details = ("'%s' -> '%s'"):format(o.note, n.note),
                })
            end
            if o.officerNote ~= n.officerNote then
                pushLog(guild, {
                    t = now, type = "ONOTE", who = name,
                    details = ("'%s' -> '%s'"):format(o.officerNote, n.officerNote),
                })
            end
        end

        local m = guild.members[name]
        if not m then m = {}; guild.members[name] = m end
        if n.online then m.lastOnline = now end
        m.lastRank  = n.rank
        m.lastLevel = n.level
        m.classFile = n.classFile
    end
end

-- =========================================================
-- Coalesced "do a diff" trigger
-- =========================================================
addon.isScanningRoster = false

local function scheduleDiff()
    if addon.isScanningRoster then return end
    if pendingSnapshot then return end

    pendingSnapshot = true
    addon:delayCall(SNAPSHOT_DEBOUNCE, function()
        pendingSnapshot = false
        if not IsInGuild() then return end

        local guildName = GetGuildInfo("player")
        if not guildName or guildName == "" then return end

        local realmName = GetRealmName() or "?"
        local key = (realmName or "?") .. "::" .. (guildName or "?")
        if key ~= addon.currentGuildKey then
            addon.currentGuildKey = key
            lastSnapshot = nil
        end
        local guild = addon:ensureGuildEntry(key)

        -- [FIX] Force UI to show offline members so they don't disappear from the snapshot
        local oldShowOffline = GetGuildRosterShowOffline()
        if not oldShowOffline then
            addon.isScanningRoster = true
            SetGuildRosterShowOffline(true)
        end

        local snap = snapshotRoster()

        -- [FIX] Restore the UI filter cleanly
        if not oldShowOffline then
            SetGuildRosterShowOffline(false)
            -- Small delay to absorb the queued GUILD_ROSTER_UPDATE events
            addon:delayCall(0.5, function() addon.isScanningRoster = false end)
        end

        local snapCount = 0
        for _ in pairs(snap) do snapCount = snapCount + 1 end

        if snapCount == 0 then return end

        local now = time()
        for name in pairs(guild.members) do
            if not snap[name] then
                if not guild.pendingLeaves[name] then
                    guild.pendingLeaves[name] = now
                    addon:delayCall(LEAVE_GRACE_SECONDS + 2, function()
                        if IsInGuild() then GuildRoster() end
                    end)
                end
            end
        end

        for name, absentSince in pairs(guild.pendingLeaves) do
            if now - absentSince >= LEAVE_GRACE_SECONDS then
                local m = guild.members[name]
                pushLog(guild, {
                    t = absentSince, type = "LEAVE", who = name,
                    details = m and ("%s (Lvl %d)"):format(m.lastRank or "", m.lastLevel or 0) or "",
                })
                guild.pendingLeaves[name] = nil
                guild.members[name] = nil

                -- Auto Ban on Leaving
                if GuildeaOrdoDB and GuildeaOrdoDB.autoBanOnLeave then
                    local officer = UnitName("player") or "System"
                    local dateStr = date("%b %d %Y")
                    local note = dateStr .. ": Quit Guild"
                    if addon.AddToBlacklist then
                        addon:AddToBlacklist(name, note)
                    end
                    print("|cFFFFCC00GuildeaOrdo|r: Auto-banned |cffffffff" .. tostring(name) .. "|r for leaving the guild.")
                end
            end
        end

        if lastSnapshot then
            diffSnapshots(lastSnapshot, snap, guild)
        else
            for name, info in pairs(snap) do
                if guild.pendingLeaves[name] then
                    guild.pendingLeaves[name] = nil
                end
                local m = guild.members[name]
                if not m then
                    guild.members[name] = {
                        lastOnline = info.online and now or nil,
                        lastRank = info.rank,
                        lastLevel = info.level,
                        classFile = info.classFile,
                    }
                end
            end
        end

        lastSnapshot = snap
        if addon.UI and addon.UI.RefreshIfShown then addon.UI:RefreshIfShown() end
    end)
end

-- Export to addon
addon.scheduleDiff = scheduleDiff
