-- GuildeaOrdo Roster UI Module
local addon = GuildeaOrdo
local UI    = addon.UI

-- =========================================================
-- Context Menu
-- =========================================================
local contextMenuFrame
function UI.ShowRosterContextMenu(name)
    if not name or name == "" then return end
    if not contextMenuFrame then contextMenuFrame = CreateFrame("Frame", "GuildeaOrdoRosterContextMenu", UIParent, "UIDropDownMenuTemplate") end
    local isSelf = (name == UnitName("player"))
    local canPromote = CanGuildPromote and CanGuildPromote() and not isSelf
    local canDemote  = CanGuildDemote  and CanGuildDemote()  and not isSelf

    local isWhite = false
    if addon.IsWhitelisted and addon:IsWhitelisted(name) then isWhite = true end

    local menu = {
        { text = name, isTitle = true, notCheckable = true },
        {
            text = isWhite and "Remove from Whitelist" or "Add to Whitelist", notCheckable = true,
            func = function() if addon.ToggleWhitelist then addon:ToggleWhitelist(name) end; UI:Refresh() end,
        },
        {
            text = "Promote", notCheckable = true, disabled = not canPromote,
            func = function()
                StaticPopupDialogs["GuildeaOrdo_CONFIRM_PROMOTE"] = { text = "Promote |cffffff00"..name.."|r by one rank?", button1 = "Promote", button2 = "Cancel", OnAccept = function() if GuildPromote then GuildPromote(name) end; if addon.RequestRosterAfterAction then addon:RequestRosterAfterAction() else GuildRoster() end end, timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3 }
                StaticPopup_Show("GuildeaOrdo_CONFIRM_PROMOTE")
            end,
        },
        {
            text = "Demote", notCheckable = true, disabled = not canDemote,
            func = function()
                StaticPopupDialogs["GuildeaOrdo_CONFIRM_DEMOTE"] = { text = "Demote |cffffff00"..name.."|r by one rank?", button1 = "Demote", button2 = "Cancel", OnAccept = function() if GuildDemote then GuildDemote(name) end; if addon.RequestRosterAfterAction then addon:RequestRosterAfterAction() else GuildRoster() end end, timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3 }
                StaticPopup_Show("GuildeaOrdo_CONFIRM_DEMOTE")
            end,
        },
        { text = "Whisper", notCheckable = true, disabled = isSelf, func = function() if ChatFrame_OpenChat then ChatFrame_OpenChat("/w "..name.." ", DEFAULT_CHAT_FRAME) end end },
        { text = "Invite to Group", notCheckable = true, disabled = isSelf, func = function() if InviteUnit then InviteUnit(name) end end },
        {
            text = "Ban Member", notCheckable = true, disabled = isSelf,
            func = function()
                StaticPopupDialogs["GuildeaOrdo_CONFIRM_BAN"] = { text = "Ban |cffffff00" .. name .. "|r ?\nThis will KICK the member and add them to the Blacklist.", button1 = "BAN (Kick + Blacklist)", button2 = "Cancel", OnAccept = function() local officer = UnitName("player") or "Officer"; local dateStr = date("%b %d %Y"); local note = officer .. " " .. dateStr .. ": banned"; if GuildUninvite then GuildUninvite(name) end; if addon.AddToBlacklist then addon:AddToBlacklist(name, note) end; if addon.RequestRosterAfterAction then addon:RequestRosterAfterAction() else GuildRoster() end end, timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3 }
                StaticPopup_Show("GuildeaOrdo_CONFIRM_BAN")
            end,
        },
        { text = "Cancel", notCheckable = true, func = function() end },
    }
    EasyMenu(menu, contextMenuFrame, "cursor", 0, 0, "MENU")
end

-- =========================================================
-- Builders & Row Collection
-- =========================================================
function UI.BuildRoster(f)
    f.rosterShowOfflineCB = CreateFrame("CheckButton", "GuildeaOrdoShowOffline", f, "OptionsBaseCheckButtonTemplate")
    f.rosterShowOfflineCB:SetSize(20, 20); f.rosterShowOfflineCB:SetPoint("TOPLEFT", f.tabLog, "BOTTOMLEFT", 0, -18); f.rosterShowOfflineCB:SetChecked(UI.rosterShowOffline)
    f.rosterShowOfflineCB:SetScript("OnClick", function(self) UI.rosterShowOffline = self:GetChecked() and true or false; UI:Refresh() end)
    f.rosterShowOfflineLabel = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.rosterShowOfflineLabel:SetPoint("LEFT", f.rosterShowOfflineCB, "RIGHT", 2, 0); f.rosterShowOfflineLabel:SetText("Show Offline")

    f.rosterPSearch = CreateFrame("EditBox", "GuildeaOrdoRosterPSearch", f, "InputBoxTemplate")
    f.rosterPSearch:SetSize(120, 20); f.rosterPSearch:SetPoint("LEFT", f.rosterShowOfflineLabel, "RIGHT", 50, 0); f.rosterPSearch:SetAutoFocus(false)
    f.rosterPSearch:SetScript("OnTextChanged", function(self) UI.rosterPlayerSearch = self:GetText() or ""; UI:Refresh() end)
    f.rosterPSearch:SetScript("OnEscapePressed", function(self) self:ClearFocus() end); f.rosterPSearch:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    f.rosterPSearchLabel = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.rosterPSearchLabel:SetPoint("BOTTOMLEFT", f.rosterPSearch, "TOPLEFT", -4, 1); f.rosterPSearchLabel:SetText("Player Search")

    f.rosterRankSearch = CreateFrame("EditBox", "GuildeaOrdoRosterRankSearch", f, "InputBoxTemplate")
    f.rosterRankSearch:SetSize(120, 20)
    f.rosterRankSearch:SetPoint("LEFT", f.rosterPSearch, "RIGHT", 24, 0)
    f.rosterRankSearch:SetAutoFocus(false)
    f.rosterRankSearch:SetScript("OnTextChanged", function(self)
        UI.rosterRankSearch = self:GetText() or ""
        UI:Refresh()
    end)
    f.rosterRankSearch:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    f.rosterRankSearch:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)

    f.rosterRankSearchLabel = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.rosterRankSearchLabel:SetPoint("BOTTOMLEFT", f.rosterRankSearch, "TOPLEFT", -4, 1)
    f.rosterRankSearchLabel:SetText("Rank Search")

    f.rosterNSearch = CreateFrame("EditBox", "GuildeaOrdoRosterNSearch", f, "InputBoxTemplate")
    f.rosterNSearch:SetSize(120, 20)
    f.rosterNSearch:SetPoint("LEFT", f.rosterRankSearch, "RIGHT", 24, 0)
    f.rosterNSearch:SetAutoFocus(false) 
    f.rosterNSearch:SetScript("OnTextChanged", function(self) UI.rosterNoteSearch = self:GetText() or ""; UI:Refresh() end)
    f.rosterNSearch:SetScript("OnEscapePressed", function(self) self:ClearFocus() end); f.rosterNSearch:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    f.rosterNSearchLabel = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.rosterNSearchLabel:SetPoint("BOTTOMLEFT", f.rosterNSearch, "TOPLEFT", -4, 1); f.rosterNSearchLabel:SetText("Note Search")

    f.rosterOffDaysInput = CreateFrame("EditBox", "GuildeaOrdoRosterOffDays", f, "InputBoxTemplate")
    f.rosterOffDaysInput:SetSize(40, 20); f.rosterOffDaysInput:SetPoint("LEFT", f.rosterNSearch, "RIGHT", 24, 0); f.rosterOffDaysInput:SetAutoFocus(false); f.rosterOffDaysInput:SetNumeric(true)
    f.rosterOffDaysInput:SetScript("OnTextChanged", function(self) UI.rosterOfflineDaysSearch = self:GetText() or ""; UI:Refresh() end)
    f.rosterOffDaysInput:SetScript("OnEscapePressed", function(self) self:ClearFocus() end); f.rosterOffDaysInput:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    f.rosterOffDaysLabel = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.rosterOffDaysLabel:SetPoint("BOTTOMLEFT", f.rosterOffDaysInput, "TOPLEFT", -4, 1); f.rosterOffDaysLabel:SetText("> Days Offline")

    f.rosterONoteEmptyBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    f.rosterONoteEmptyBtn:SetSize(150, 24); f.rosterONoteEmptyBtn:SetPoint( "TOPRIGHT", -18, -102); f.rosterONoteEmptyBtn:SetText("|cFFFFCC00ONote Empty Newbies|r")
    if f.rosterONoteEmptyBtn:GetFontString() then f.rosterONoteEmptyBtn:GetFontString():SetTextColor(1, 0.8, 0) end
        f.rosterONoteEmptyBtn:SetScript("OnClick", function()
        local list = {}

        local oldShowOffline = GetGuildRosterShowOffline()
        if not oldShowOffline then
            addon.isScanningRoster = true
            SetGuildRosterShowOffline(true)
            end

        for i = 1, GetNumGuildMembers() do
        local name, _, _, _, _, _, _, onote = GetGuildRosterInfo(i)
        if name and (not onote or onote == "") then table.insert(list, {name = name}) end
        end

        if not oldShowOffline then
        SetGuildRosterShowOffline(false)
        addon:delayCall(0.5, function() addon.isScanningRoster = false end)
        end

        if #list == 0 then print("|cff00ff00GuildeaOrdo:|r No members with empty Officer Notes."); return end
        local dateTag = (GuildeaOrdoDB.bracketLeft or "[") .. date("%b %d %Y") .. (GuildeaOrdoDB.bracketRight or "]")
        StaticPopupDialogs["GuildeaOrdo_CONFIRM_ONOTE_EMPTY"] = {
        text = "Insert today's date " .. dateTag .. " for |cffffff00" .. #list .. "|r members?",
        button1 = "Proceed", button2 = "Cancel",
        OnAccept = function()
        UI.ProcessBatch("ONote Empty", list, function(name)
        local oldShow = GetGuildRosterShowOffline()
        if not oldShow then
        addon.isScanningRoster = true
        SetGuildRosterShowOffline(true)
        end
        for i = 1, GetNumGuildMembers() do
        if GetGuildRosterInfo(i) == name then
        GuildRosterSetOfficerNote(i, dateTag)
        break
        end
        end
        if not oldShow then
        SetGuildRosterShowOffline(false)
        addon:delayCall(0.5, function() addon.isScanningRoster = false end)
        end
        end)
        end,
        timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3
        }
        StaticPopup_Show("GuildeaOrdo_CONFIRM_ONOTE_EMPTY")
    end)

    f.rosterMassKickBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    f.rosterMassKickBtn:SetSize(150, 24); f.rosterMassKickBtn:SetPoint("BOTTOMRIGHT", -18, 18); f.rosterMassKickBtn:SetText("Mass Kick List")
    f.rosterMassKickBtn:SetScript("OnClick", function()
        local rows = addon.RosterRowsCache or {}
        if #rows == 0 or UI.rosterShowOffline == false then if UI.rosterShowOffline == false then print("|cff00ff00GuildeaOrdo:|r No Offline Selection on, Action aborted ") end; return end
        StaticPopupDialogs["GuildeaOrdo_CONFIRM_MASS_KICK"] = { text = "WARNING: Kick |cffffff00" .. #rows .. "|r currently filtered members?", button1 = "KICK ALL", button2 = "Cancel", OnAccept = function() StaticPopupDialogs["GuildeaOrdo_CONFIRM_MASS_KICK_2"] = { text = "SECOND CONFIRMATION: Are you absolutely sure? This cannot be undone.", button1 = "YES, KICK", button2 = "Cancel", OnAccept = function() UI.ProcessBatch("Mass Kick", rows, function(name) if not addon:IsWhitelisted(name) then if GuildUninvite then GuildUninvite(name) end end end) end, timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3 }; StaticPopup_Show("GuildeaOrdo_CONFIRM_MASS_KICK_2") end, timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3 }
        StaticPopup_Show("GuildeaOrdo_CONFIRM_MASS_KICK")
    end)

    f.groupAltsCB = CreateFrame("CheckButton", "GuildeaOrdoGroupAltsCB", f, "OptionsBaseCheckButtonTemplate")
    f.groupAltsCB:SetSize(20, 20); f.groupAltsCB:SetPoint("BOTTOMLEFT", 24, 22); f.groupAltsCB:SetChecked(UI.groupAltsWithMain)
    f.groupAltsCB:SetScript("OnClick", function(self) UI.groupAltsWithMain = self:GetChecked() and true or false; UI:Refresh() end)
    f.groupAltsLabel = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.groupAltsLabel:SetPoint("LEFT", f.groupAltsCB, "RIGHT", 2, 0); f.groupAltsLabel:SetText("Group Alts With Main")
end

function UI.CollectRosterRows()
local guild = addon:GetCurrentGuild()
local rows = {}
if not guild then return rows, 0, 0 end

    local online, total = 0, 0
    local needle = UI.lowerSafe(UI.rosterPlayerSearch)
    local rankNeedle  = UI.lowerSafe(UI.rosterRankSearch)
    local noteNeedle  = UI.lowerSafe(UI.rosterNoteSearch)

    local lMag = addon.escapePattern(GuildeaOrdoDB and GuildeaOrdoDB.bracketLeft or "[")
    local rMag = addon.escapePattern(GuildeaOrdoDB and GuildeaOrdoDB.bracketRight or "]")

    local oldShowOffline = GetGuildRosterShowOffline()
    if not oldShowOffline then
        addon.isScanningRoster = true
        SetGuildRosterShowOffline(true)
        end

        local n = GetNumGuildMembers() or 0
        for i = 1, n do
        local name, rank, rankIndex, level, _, _, note, officerNote, isOnline, _, classFile = GetGuildRosterInfo(i)
        if name and name ~= "" then
            total = total + 1
            if isOnline then online = online + 1 end
            local pass = true
            if not UI.rosterShowOffline and not isOnline then pass = false end
            if pass and needle ~= "" and not UI.lowerSafe(name):find(needle, 1, true) then pass = false end
            if pass and noteNeedle ~= "" then
                local nMatch = (note and UI.lowerSafe(note):find(noteNeedle, 1, true)) or (officerNote and UI.lowerSafe(officerNote):find(noteNeedle, 1, true))
                if not nMatch then pass = false end
            end

            if pass and rankNeedle ~= "" then
                local rMatch = false
                if rank then
                    rMatch = UI.lowerSafe(rank):find(rankNeedle, 1, true)
                end
                if not rMatch and rankIndex then
                    rMatch = tostring(rankIndex):find(rankNeedle, 1, true)
                end
                if not rMatch then pass = false end
            end

            local rec = guild.members[name]
            local serverEpoch = nil
            if not isOnline then
                local y, m, d, h = GetGuildRosterLastOnline(i)
                if y or m or d or h then
                    local totalSecs = ((y or 0)*365*24*3600) + ((m or 0)*30*24*3600) + ((d or 0)*24*3600) + ((h or 0)*3600)
                    if totalSecs > 0 then serverEpoch = time() - totalSecs end
                end
            end

            local hasOffDaysFilter = (UI.rosterOfflineDaysSearch ~= nil and UI.rosterOfflineDaysSearch ~= "")
            if pass and hasOffDaysFilter then
                if isOnline then pass = false else
                    local filterOffDays = tonumber(UI.rosterOfflineDaysSearch) or 0
                    local lastSeenTs = (rec and rec.lastOnline) or serverEpoch
                    if lastSeenTs then
                        local daysOffline = (time() - lastSeenTs) / 86400
                        if daysOffline <= filterOffDays then pass = false end
                    else pass = false end
                end
            end
            
            if pass then
                table.insert(rows, {
                    name = name, rank = rank or "", rankIndex = rankIndex or 0, level = level or 0, online = isOnline and true or false, note = note or "", officerNote = officerNote or "",
                    classFile = classFile or (rec and rec.classFile) or "",
                    joinDate = (officerNote and string.match(officerNote, lMag .. "(%a%a%a %d%d %d%d%d%d)" .. rMag)) or ((rec and rec.joinDateExact) and rec.joinDate) or nil,
                    lastSeen = isOnline and time() or (rec and rec.lastOnline) or serverEpoch,
                    main = guild.alts[name],
                })
            end
        end
    end

                if not oldShowOffline then
                    SetGuildRosterShowOffline(false)
                    addon:delayCall(0.5, function() addon.isScanningRoster = false end)
                    end

    local key, rev = UI.rosterSortBy, UI.rosterSortReverse
    table.sort(rows, function(a, b)
        local av, bv
        if key == "level" then av, bv = a.level, b.level
        elseif key == "name" then av, bv = a.name:lower(), b.name:lower()
        elseif key == "online" then
            local at = a.online and math.huge or (a.lastSeen or 0); local bt = b.online and math.huge or (b.lastSeen or 0)
            if not rev then return at > bt else return at < bt end
        elseif key == "rank" then av, bv = a.rankIndex, b.rankIndex
        elseif key == "joinDate" then av, bv = (a.joinDate or "9999-99-99"), (b.joinDate or "9999-99-99")
        elseif key == "note" then av, bv = a.note:lower(), b.note:lower()
        elseif key == "onote" then av, bv = a.officerNote:lower(), b.officerNote:lower()
        else av, bv = a.name:lower(), b.name:lower() end
        
        -- Fallback: if values are equal, sort alphabetically by name
        if av == bv then return a.name:lower() < b.name:lower() end
        if rev then return av > bv else return av < bv end
    end)

    if UI.groupAltsWithMain then
        local byMain, newRows, seen = {}, {}, {}
        for _, r in ipairs(rows) do if r.main then byMain[r.main] = byMain[r.main] or {}; table.insert(byMain[r.main], r) end end
        for _, r in ipairs(rows) do
            if not seen[r.name] then
                if not r.main then
                    table.insert(newRows, r); seen[r.name] = true
                    local kids = byMain[r.name]
                    if kids then for _, alt in ipairs(kids) do if not seen[alt.name] then table.insert(newRows, alt); seen[alt.name] = true end end end
                end
            end
        end
        for _, r in ipairs(rows) do if not seen[r.name] then table.insert(newRows, r); seen[r.name] = true end end
        rows = newRows
    end
    return rows, online, total
end
