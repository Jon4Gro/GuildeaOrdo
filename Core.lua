-- GuildeaOrdo Core
-- Wrath 3.3.5a native guild roster tracking, event log, alts management.

GuildeaOrdo = GuildeaOrdo or {}
local addon = GuildeaOrdo
addon.version = "1.0" -- 1.6: Purge Blacklist, dynamic search, SavedVariables migration (Auto-Invite), codebase refactoring

-- Global states
local currentGuildKey      -- realm::guildname for the currently active guild

-- =========================================================
-- SavedVariables bootstrap
-- =========================================================
function addon:ensureDB()
    if type(GuildeaOrdoDB)     ~= "table" then GuildeaOrdoDB     = {} end
    if type(GuildeaOrdoCharDB) ~= "table" then GuildeaOrdoCharDB = {} end
    if type(GuildeaOrdoCharDB.massPromote) ~= "table" then GuildeaOrdoCharDB.massPromote = {} end
    if GuildeaOrdoCharDB.openWithGuild == nil then GuildeaOrdoCharDB.openWithGuild = true end
    if GuildeaOrdoCharDB.closeWithGuild == nil then GuildeaOrdoCharDB.closeWithGuild = true end
    if type(GuildeaOrdoDB.guilds) ~= "table" then GuildeaOrdoDB.guilds = {} end
    if type(GuildeaOrdoDB.macros) ~= "table" then GuildeaOrdoDB.macros = {} end
    if not GuildeaOrdoDB.version then GuildeaOrdoDB.version = 3 end
    if not GuildeaOrdoDB.batchSize then GuildeaOrdoDB.batchSize = 2 end
if GuildeaOrdoDB.showMinimapButton == nil then GuildeaOrdoDB.showMinimapButton = true end
    if not GuildeaOrdoDB.minimapRotation then GuildeaOrdoDB.minimapRotation = 0 end
    if not GuildeaOrdoDB.minimapDistance then GuildeaOrdoDB.minimapDistance = 80 end
    if GuildeaOrdoDB.bracketLeft == nil then GuildeaOrdoDB.bracketLeft = "[" end
    if GuildeaOrdoDB.bracketRight == nil then GuildeaOrdoDB.bracketRight = "]" end

    -- Migration: Move autoInvite from account-wide GuildeaOrdoDB to character-specific GuildeaOrdoCharDB
    if type(GuildeaOrdoDB.autoInvite) == "table" then
        GuildeaOrdoCharDB.autoInvite = GuildeaOrdoDB.autoInvite
        GuildeaOrdoDB.autoInvite = nil
    end

    if type(GuildeaOrdoCharDB.autoInvite) ~= "table" then
        GuildeaOrdoCharDB.autoInvite = {
            enabled = false,
            phrase = "",
            groupinv = "",
            replyOn = "Auto-Sending Guild invite ",
            replyOff = "Auto-invites are currently disabled",
            minLvl = 1,
            replyLow = "Your level is too low for auto-invite. Please level up first!"
        }
    else
        if GuildeaOrdoCharDB.autoInvite.groupinv == nil then GuildeaOrdoCharDB.autoInvite.groupinv = "" end
        if GuildeaOrdoCharDB.autoInvite.minLvl == nil then GuildeaOrdoCharDB.autoInvite.minLvl = 1 end
        if GuildeaOrdoCharDB.autoInvite.replyLow == nil then GuildeaOrdoCharDB.autoInvite.replyLow = "" end
        if GuildeaOrdoCharDB.autoInvite.groupMinutes == nil then GuildeaOrdoCharDB.autoInvite.groupMinutes = 15 end
    end
    if not GuildeaOrdoDB.spamTotalMinutes then GuildeaOrdoDB.spamTotalMinutes = 0 end
    if type(GuildeaOrdoDB.blacklist) ~= "table" then GuildeaOrdoDB.blacklist = {} end
    if GuildeaOrdoDB.blacklistReply == nil then GuildeaOrdoDB.blacklistReply = "You are currently blacklisted from auto-invites." end
    if GuildeaOrdoDB.autoBanOnLeave == nil then GuildeaOrdoDB.autoBanOnLeave = false end
    -- migrate old boolean blacklist entries to string notes ("" = no note)
    for k, v in pairs(GuildeaOrdoDB.blacklist) do
        if type(v) == "boolean" then
            GuildeaOrdoDB.blacklist[k] = ""
        end
    end
end

-- =========================================================
-- Macros API (account-wide saved messages bound to a channel)
-- =========================================================
function addon:GetMacros()
    if type(GuildeaOrdoDB) ~= "table" or type(GuildeaOrdoDB.macros) ~= "table" then
        return {}
    end
    return GuildeaOrdoDB.macros
end

function addon:AddMacro(channel, text)
    if not channel or channel == "" then return false, "Pick a channel." end
    if not text or text == "" then return false, "Message cannot be empty." end
    GuildeaOrdoDB.macros = GuildeaOrdoDB.macros or {}
    table.insert(GuildeaOrdoDB.macros, { channel = channel, text = text })
    return true
end

function addon:RemoveMacro(index)
    if not GuildeaOrdoDB.macros then return end
    if type(index) ~= "number" then return end
    if index < 1 or index > #GuildeaOrdoDB.macros then return end
    table.remove(GuildeaOrdoDB.macros, index)
end

function addon:SendMacro(index)
    if not GuildeaOrdoDB.macros then return false, "No macros." end
    local m = GuildeaOrdoDB.macros[index]
    if not m then return false, "Macro not found." end
    return addon:Broadcast(m.channel, m.text)
end

local NAMED_CHANNELS = {
    SAY = true, YELL = true, GUILD = true, OFFICER = true,
    PARTY = true, RAID = true, RAID_WARNING = true,
}

function addon:Broadcast(channel, text)
    if not channel or channel == "" then return false, "No channel." end
    if not text or text == "" then return false, "Empty message." end
    local num = tonumber(channel)
    if num and num >= 1 and num <= 9 then
        SendChatMessage(text, "CHANNEL", nil, num)
        return true
    end
    local up = channel:upper()
    if NAMED_CHANNELS[up] then
        if up == "RAID_WARNING" then
            SendChatMessage(text, "RAID_WARNING")
        else
            SendChatMessage(text, up)
        end
        return true
    end
    return false, "Unsupported channel: " .. tostring(channel)
end

local function guildKey(realmName, guildName)
    return (realmName or "?") .. "::" .. (guildName or "?")
end

function addon:ensureGuildEntry(key)
    local g = GuildeaOrdoDB.guilds[key]
    if not g then
        g = { members = {}, log = {}, alts = {}, whitelist = {}}
        GuildeaOrdoDB.guilds[key] = g
    end
    if not g.members       then g.members       = {} end
    if not g.log           then g.log           = {} end
    if not g.alts          then g.alts          = {} end
    if not g.pendingLeaves then g.pendingLeaves = {} end
    if not g.whitelist     then g.whitelist     = {} end
    return g
end

function addon:GetCurrentGuild()
    if not addon.currentGuildKey then return nil end
    return GuildeaOrdoDB and GuildeaOrdoDB.guilds and GuildeaOrdoDB.guilds[addon.currentGuildKey]
end

function addon:GetCurrentGuildKey()
    return addon.currentGuildKey
end

-- =========================================================
-- Alts Management API
-- =========================================================
function addon:GetMainOf(name)
    local g = self:GetCurrentGuild()
    return g and g.alts and g.alts[name] or nil
end

function addon:GetAltsOf(mainName)
    local g = self:GetCurrentGuild()
    local alts = {}
    if g and g.alts then
        for alt, main in pairs(g.alts) do
            if main == mainName then
                table.insert(alts, alt)
            end
        end
    end
    table.sort(alts)
    return alts
end

function addon:SetAlt(altName, mainName)
    local g = self:GetCurrentGuild()
    if not g then return false, "No active guild data." end
    if not altName or altName == "" then return false, "Invalid alt name." end
    if mainName == "" then mainName = nil end
    
    if mainName then
        if altName == mainName then return false, "A player cannot be their own main." end
        g.alts[altName] = mainName
        return true, ("Tagged %s as alt of %s."):format(altName, mainName)
    else
        g.alts[altName] = nil
        return true, ("Removed alt status from %s."):format(altName)
    end
end

function addon:GetMemberRecord(name)
    local g = self:GetCurrentGuild()
    return g and g.members and g.members[name] or nil
end

-- =========================================================
-- Minimap Button
-- =========================================================
local minimapButton

local function updateMinimapButtonPosition()
    if not minimapButton or not Minimap then return end
    local rot = (GuildeaOrdoDB and GuildeaOrdoDB.minimapRotation or 0) % 360
    if rot < 0 then rot = 0 end
    if rot > 360 then rot = 360 end
    local dist = GuildeaOrdoDB and GuildeaOrdoDB.minimapDistance or 80
    if dist < 20 then dist = 20 end
    if dist > 240 then dist = 240 end
    local rad = math.rad(rot)
    local x = math.cos(rad) * dist
    local y = math.sin(rad) * dist
    minimapButton:ClearAllPoints()
    minimapButton:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

local function createMinimapButton()
    if minimapButton or not Minimap then return end
    local b = CreateFrame("Button", "GuildeaOrdoMinimapButton", Minimap)
    b:SetSize(32, 32)
    b:SetFrameStrata("MEDIUM")
    b:SetFrameLevel((Minimap:GetFrameLevel() or 0) + 8)

    local icon = b:CreateTexture(nil, "ARTWORK")
    icon:SetSize(18, 18)
    icon:SetPoint("CENTER")
    icon:SetTexture("Interface\\AddOns\\GuildeaOrdo\\GuildeaOrdo")
    icon:SetTexCoord(0.06, 0.94, 0.06, 0.94)
    b.icon = icon

    local border = b:CreateTexture(nil, "OVERLAY")
    border:SetSize(56, 56)
    border:SetPoint("TOPLEFT", -1, 1)
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    b.border = border

    b:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
    local ht = b:GetHighlightTexture()
    if ht then
        ht:SetBlendMode("ADD")
        ht:SetPoint("CENTER", icon)
        ht:SetSize(18, 18)
    end

    b:SetScript("OnClick", function(_, mouseBtn)
        if mouseBtn == "LeftButton" and addon.UI and addon.UI.Toggle then
            addon.UI:Toggle()
        end
    end)

    b:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("|cFFFFCC00GuildeaOrdo|r")
        GameTooltip:AddLine("Left-click to open/close", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)

    minimapButton = b
    updateMinimapButtonPosition()
end

function addon:UpdateMinimapButton()
    local enabled = GuildeaOrdoDB and GuildeaOrdoDB.showMinimapButton
    if enabled then
        if not minimapButton then createMinimapButton() end
        if minimapButton then
            minimapButton:Show()
            updateMinimapButtonPosition()
        end
    else
        if minimapButton then minimapButton:Hide() end
    end
end

addon.UpdateMinimapPos = updateMinimapButtonPosition

-- =========================================================
-- Helper function to auto-escape Lua pattern magic characters
-- =========================================================
function addon.escapePattern(str)
if not str then return "" end
    return (str:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1"))
    end

-- =========================================================
-- Roster Request Helpers
-- =========================================================
function addon:RequestRoster()
    if IsInGuild() then GuildRoster() end
end

function addon:RequestRosterAfterAction()
    addon:delayCall(0.5, function()
        if IsInGuild() then GuildRoster() end
    end)
end

-- =========================================================
-- Guild Frame Hook (Moved to be defined BEFORE it is called)
-- =========================================================
local function hookGuildFrame()
    if GuildFrame and not GuildFrame.__GuildeaOrdoHooked then
        GuildFrame.__GuildeaOrdoHooked = true
        GuildFrame:HookScript("OnShow", function()
            if GuildeaOrdoCharDB and GuildeaOrdoCharDB.openWithGuild then
                if addon.UI and addon.UI.Show then addon.UI:Show() end
            end
        end)
        GuildFrame:HookScript("OnHide", function()
            if GuildeaOrdoCharDB and GuildeaOrdoCharDB.closeWithGuild then
                if addon.UI and addon.UI.Hide then addon.UI:Hide() end
            end
        end)
    end
end

-- =========================================================
-- Macro Spam Engine
-- =========================================================
local spamEngine = CreateFrame("Frame")
addon.spamTimer = 0
addon.spamTotalElapsed = 0

spamEngine:SetScript("OnUpdate", function(self, elapsed)
if not addon.spamActive then return end

    local intervalSecs = (addon.spamInterval or 5) * 60
    addon.spamTimer = addon.spamTimer + elapsed

    if addon.spamTotalLimit and addon.spamTotalLimit > 0 then
    addon.spamTotalElapsed = addon.spamTotalElapsed + elapsed
        if addon.spamTotalElapsed >= (addon.spamTotalLimit * 60) then
        addon.spamActive = false
            print("|cFFFFCC00GuildeaOrdo|r: Macro Spam Ended (Duration expired).")
            if addon.UI and addon.UI.RefreshIfShown then addon.UI:RefreshIfShown() end
                return
                end
                end

                if addon.spamTimer >= intervalSecs then
                    addon.spamTimer = 0
                    if addon.spamMacros then
                    for idx, active in pairs(addon.spamMacros) do
                        if active then
                        addon:SendMacro(idx)
                        end
                    end
            end
        end
end)

-- =========================================================
-- Main Backend Event Listener
-- =========================================================
local backend = CreateFrame("Frame")
backend:RegisterEvent("ADDON_LOADED")
backend:RegisterEvent("PLAYER_LOGIN")
backend:RegisterEvent("GUILD_ROSTER_UPDATE")
backend:RegisterEvent("CHAT_MSG_WHISPER")
backend:RegisterEvent("WHO_LIST_UPDATE")
backend:RegisterEvent("CHAT_MSG_OFFICER") 

backend:SetScript("OnEvent", function(self, event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12)
    if event == "ADDON_LOADED" then
        if arg1 == "GuildeaOrdo" then
            addon:ensureDB()
            if GuildeaOrdoDB and GuildeaOrdoDB.spamTotalMinutes then
                addon.spamTotalLimit = GuildeaOrdoDB.spamTotalMinutes
            end
            if addon.UpdateMinimapButton then addon:UpdateMinimapButton() end
        elseif arg1 == "Blizzard_GuildUI" then
            hookGuildFrame() 
        end
    elseif event == "PLAYER_LOGIN" then
        hookGuildFrame() 
        if IsInGuild() then GuildRoster() end
        if addon.UpdateMinimapButton then addon:UpdateMinimapButton() end
    elseif event == "GUILD_ROSTER_UPDATE" then
        if IsInGuild() then addon.scheduleDiff() end
    elseif event == "WHO_LIST_UPDATE" then
        addon:ProcessWhoLevelCheck() 
    elseif event == "CHAT_MSG_OFFICER" then
        local msg, sender = arg1, arg2
        if not msg or not sender then return end

        local cleanSender = strsplit("-", sender):lower()
        local myName = (UnitName("player") or ""):lower()
        if cleanSender == myName then return end

        if msg == "GuildeaOrdo Blacklist share:" then
            print(string.format("|cFFFFCC00GuildeaOrdo|r: Received blacklist share from |cffffffff%s|r. Adding/updating entries.", sender or "?"))
        elseif msg:match("^GuildeaOrdo BL: ") then
            local rest = msg:sub(14):match("^%s*(.-)%s*$")
            if rest and rest ~= "" then
                local pos = 1
                while true do
                    local s, e = rest:find("||", pos, true)
                    local part = s and rest:sub(pos, s-1) or rest:sub(pos)
                    part = part:match("^%s*(.-)%s*$")
                    if part and part ~= "" then
                        local name, note = part:match("^([^%(]+)%s*%((.*)%)%s*$")
                        if not name then
                            name = part
                            note = ""
                        end
                        name = name:match("^%s*(.-)%s*$")
                        note = (note or ""):match("^%s*(.-)%s*$")
                        if name ~= "" and addon.AddToBlacklist then
                            addon:AddToBlacklist(name, note)
                        end
                    end
                    if not s then break end
                    pos = e + 1
                end
            end
        end
        elseif event == "CHAT_MSG_WHISPER" then
        local msg, sender = arg1, arg2

        -- ADD THIS LINE: Track the last person who whispered for the /go invl command
        addon.lastWhisperedPlayer = sender

        -- 1. Auto Guild Invite
        if GuildeaOrdoDB and GuildeaOrdoCharDB.autoInvite then
            local conf = GuildeaOrdoCharDB.autoInvite
            if conf.phrase and conf.phrase ~= "" and addon.containsTriggerWord(msg, conf.phrase) then
                if addon:IsBlacklisted(sender) then
                    local breply = addon:GetBlacklistReply()
                    if breply and breply ~= "" then
                        SendChatMessage(breply, "WHISPER", nil, sender)
                    end
                    return
                end

                if conf.enabled then
                    local cleanSender = strsplit("-", sender)
                    addon.pendingLevelChecks = addon.pendingLevelChecks or {}
                    addon.pendingLevelChecks[cleanSender:lower()] = sender

                    -- Snapshot the active panel state before SetWhoToUI(1) hijacks the UI
                    if addon._friendsFrameShown == nil then
                        addon._friendsFrameShown = FriendsFrame and FriendsFrame:IsShown() or false
                        addon._friendsFrameTab = FriendsFrame and PanelTemplates_GetSelectedTab(FriendsFrame) or 1

                        -- Snapshot non-social standard UI panels to prevent them from being wiped out
                        addon._savedPanels = {
                            fullscreen = GetUIPanel("fullscreen"),
                  doublewide = GetUIPanel("doublewide"),
                  left       = GetUIPanel("left"),
                  center     = GetUIPanel("center"),
                  right      = GetUIPanel("right")
                        }
                        end

                        SetWhoToUI(1)
                        SendWho('n-"' .. cleanSender .. '"')
                        else
                    if conf.replyOff and conf.replyOff ~= "" then
                        SendChatMessage(conf.replyOff, "WHISPER", nil, sender)
                    end
                end
            end
        end

        -- 2. Auto Group Invite
        if addon.groupInviteActive then
            local groupPhrase = GuildeaOrdoDB and GuildeaOrdoCharDB.autoInvite and GuildeaOrdoCharDB.autoInvite.groupinv or ""
            if addon.containsTriggerWord(msg, groupPhrase) then
                if addon:IsBlacklisted(sender) then
                    local breply = addon:GetBlacklistReply()
                    if breply and breply ~= "" then
                        SendChatMessage(breply, "WHISPER", nil, sender)
                    end
                    return
                end
                InviteUnit(sender)
            end
        end
    end
end)
