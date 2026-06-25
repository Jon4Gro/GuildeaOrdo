-- GildeaOrdo Ranks UI Module
local addon = GildeaOrdo
local UI    = addon.UI

local function parseJoinDateToDays(dateStr)
    if not dateStr then return -1 end
    local m, d2, y2 = string.match(dateStr:lower(), "^(%S+)%s+(%d%d)%s+(%d%d%d%d)$")
    if m and d2 and y2 then
        local map = { jan=1, feb=2, mar=3, apr=4, may=5, jun=6, jul=7, aug=8, sep=9, oct=10, nov=11, dec=12, ["mär"]=3, mai=5, okt=10, dez=12 }
        local ts = time({year=tonumber(y2), month=map[m] or 1, day=tonumber(d2), hour=12, min=0, sec=0})
        if ts then return math.floor((time() - ts) / 86400) end
    end
    local y, mStr, d = string.match(dateStr, "^(%d%d%d%d)%-(%d%d)%-(%d%d)$")
    if y and mStr and d then
        local ts = time({year=tonumber(y), month=tonumber(mStr), day=tonumber(d), hour=12, min=0, sec=0})
        if ts then return math.floor((time() - ts) / 86400) end
    end
    return -1
end

function UI.BuildRanks(f)
    f.ranksConfigPanel = CreateFrame("Frame", nil, f)
    f.ranksConfigPanel:SetPoint("TOPRIGHT", -13, -60); f.ranksConfigPanel:SetSize(300, 410)
    f.ranksConfigPanel:SetBackdrop(UI.PANEL_BACKDROP); f.ranksConfigPanel:SetBackdropColor(0, 0, 0, 0.6)

    f.rankConfigLabel = f.ranksConfigPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    f.rankConfigLabel:SetPoint("TOP", 0, -10); f.rankConfigLabel:SetText("|cFFFFCC00Mass Promote Criteria|r"); f.rankConfigLabel:SetTextColor(1, 0.8, 0)

    f.rankRows = {}
    for i = 2, 10 do
        local row = CreateFrame("Frame", nil, f.ranksConfigPanel)
        row:SetSize(280, 24); row:SetPoint("TOPLEFT", 10, -20 - ((i - 1) * 26))

        local cb = CreateFrame("CheckButton", nil, row, "OptionsBaseCheckButtonTemplate")
        cb:SetSize(20, 20); cb:SetPoint("LEFT", 0, 0)
        local nameStr = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        nameStr:SetPoint("LEFT", cb, "RIGHT", 4, 0); nameStr:SetWidth(95); nameStr:SetJustifyH("LEFT")

        local function mkEb(anchor)
            local e = CreateFrame("EditBox", nil, row)
            e:SetSize(48, 20); e:SetPoint("LEFT", anchor, "RIGHT", anchor == nameStr and 12 or 18, 0); e:SetAutoFocus(false); e:SetNumeric(true); e:SetFontObject("ChatFontSmall")
            e:SetBackdrop({ bgFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = true, tileSize = 16, edgeSize = 8, insets = { left = 3, right = 3, top = 3, bottom = 3 } })
            e:SetBackdropColor(0, 0, 0, 0.85); e:SetTextInsets(5, 5, 1, 1); e:SetTextColor(1, 1, 1, 1)
            return e
        end
        local minDays, maxOff = mkEb(nameStr), mkEb(mkEb(nameStr))

        local saved = GildeaOrdoCharDB and GildeaOrdoCharDB.massPromote and GildeaOrdoCharDB.massPromote[i] or {}
        cb:SetChecked(saved.checked or false); minDays:SetText(saved.minDays or ""); maxOff:SetText(saved.maxOff or "")

        cb:SetScript("OnClick", function(self) if GildeaOrdoCharDB then GildeaOrdoCharDB.massPromote[i] = GildeaOrdoCharDB.massPromote[i] or {}; GildeaOrdoCharDB.massPromote[i].checked = self:GetChecked() and true or false end; UI:Refresh() end)
        minDays:SetScript("OnTextChanged", function(self) if GildeaOrdoCharDB then GildeaOrdoCharDB.massPromote[i] = GildeaOrdoCharDB.massPromote[i] or {}; GildeaOrdoCharDB.massPromote[i].minDays = self:GetText() end; UI:Refresh() end)
        maxOff:SetScript("OnTextChanged", function(self) if GildeaOrdoCharDB then GildeaOrdoCharDB.massPromote[i] = GildeaOrdoCharDB.massPromote[i] or {}; GildeaOrdoCharDB.massPromote[i].maxOff = self:GetText() end; UI:Refresh() end)

        f.rankRows[i] = { frame = row, cb = cb, nameStr = nameStr, minDays = minDays, maxOff = maxOff }
    end
    
    local minDaysLbl = f.ranksConfigPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    minDaysLbl:SetPoint("BOTTOM", f.rankRows[2].minDays, "TOP", 0, 2); minDaysLbl:SetText("Min Days")
    local maxOffLbl = f.ranksConfigPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    maxOffLbl:SetPoint("BOTTOM", f.rankRows[2].maxOff, "TOP", 0, 2); maxOffLbl:SetText("Max Off")

    f.ranksMultiPromoteBtn = CreateFrame("Button", nil, f.ranksConfigPanel, "UIPanelButtonTemplate")
    f.ranksMultiPromoteBtn:SetSize(180, 26); f.ranksMultiPromoteBtn:SetPoint("BOTTOM", 0, 15); f.ranksMultiPromoteBtn:SetText("|cFFFFCC00Mass Promote Selected|r")
    if f.ranksMultiPromoteBtn:GetFontString() then f.ranksMultiPromoteBtn:GetFontString():SetTextColor(1, 0.8, 0) end
    f.ranksMultiPromoteBtn:SetScript("OnClick", function()
        local rows = addon.RanksRowsCache or {}
        if #rows == 0 then print("|cff00ff00GildeaOrdo:|r No members match the selected conditions."); return end
        StaticPopupDialogs["GildeaOrdo_CONFIRM_MULTI_PROMOTE"] = { text = "Are you sure you want to promote these |cffffff00" .. #rows .. "|r members?", button1 = "Promote All", button2 = "Cancel", OnAccept = function() UI.ProcessBatch("Mass Promote", rows, function(name) if not addon:IsWhitelisted(name) then if GuildPromote then GuildPromote(name) end end end) end, timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3 }
        StaticPopup_Show("GildeaOrdo_CONFIRM_MULTI_PROMOTE")
    end)
end

function UI.CollectRanksRows()
local guild = addon:GetCurrentGuild()
local rows = {}
if not guild or not UI.frame or not UI.frame.rankRows then return rows end

    local lMag = addon.escapePattern(GildeaOrdoDB and GildeaOrdoDB.bracketLeft or "[")
    local rMag = addon.escapePattern(GildeaOrdoDB and GildeaOrdoDB.bracketRight or "]")
    local numRanks = GuildControlGetNumRanks() or 0

    -- Force Show Offline temporarily to ensure we scan the whole roster
    local oldShowOffline = GetGuildRosterShowOffline()
    if not oldShowOffline then
        addon.isScanningRoster = true
        SetGuildRosterShowOffline(true)
        end

        for j = 1, GetNumGuildMembers() or 0 do
        local name, rank, rankIndex, level, _, _, note, officerNote, isOnline, _, classFile = GetGuildRosterInfo(j)
        if name then
            local rowUI = UI.frame.rankRows[rankIndex + 1]
            if rowUI and rowUI.cb:GetChecked() and (rankIndex + 1) <= numRanks and (rankIndex + 1 > 1) then
                local minDays = tonumber(rowUI.minDays:GetText()) or 0
                local maxOff = tonumber(rowUI.maxOff:GetText())
                local rec = guild.members[name]
                local extractedDate = (officerNote and string.match(officerNote, (GildeaOrdoDB and GildeaOrdoDB.bracketLeftMagic or "%[") .. "(%S+ %d%d %d%d%d%d)" .. (GildeaOrdoDB and GildeaOrdoDB.bracketRightMagic or "%]"))) or ((rec and rec.joinDateExact) and rec.joinDate) or nil

                local serverEpoch
                if not isOnline then
                    local yy, mm, dd, hh = GetGuildRosterLastOnline(j)
                    if yy or mm or dd or hh then local totalSecs = ((yy or 0)*365*24*3600) + ((mm or 0)*30*24*3600) + ((dd or 0)*24*3600) + ((hh or 0)*3600); if totalSecs > 0 then serverEpoch = time() - totalSecs end end
                end

                local daysJoined = parseJoinDateToDays(extractedDate)
                local lastSeenTs = isOnline and time() or (rec and rec.lastOnline) or serverEpoch
                local daysOffline = 0
                if not isOnline then daysOffline = lastSeenTs and ((time() - lastSeenTs) / 86400) or 9999 end

                local pass = true
                if daysJoined == -1 then if minDays > 0 then pass = false end elseif daysJoined < minDays then pass = false end
                if maxOff and daysOffline > maxOff then pass = false end

                if pass then
                    table.insert(rows, { name = name, rank = rank or "", rankIndex = rankIndex or 0, level = level or 0, online = isOnline and true or false, note = note or "", officerNote = officerNote or "", classFile = classFile or (rec and rec.classFile) or "", joinDate = extractedDate, lastSeen = lastSeenTs, main = guild.alts[name] })
                    end
                end
            end
        end

                -- Restore original Show Offline state
                if not oldShowOffline then
                    SetGuildRosterShowOffline(false)
                    addon:delayCall(0.5, function() addon.isScanningRoster = false end)
                end

                local key, rev = UI.rosterSortBy, UI.rosterSortReverse
    
    local key, rev = UI.rosterSortBy, UI.rosterSortReverse
    table.sort(rows, function(a, b)
        local av, bv
        if key == "name" then av, bv = a.name:lower(), b.name:lower()
        elseif key == "online" then local at = a.online and math.huge or (a.lastSeen or 0); local bt = b.online and math.huge or (b.lastSeen or 0); if not rev then return at > bt else return at < bt end
        elseif key == "rank" then av, bv = a.rankIndex, b.rankIndex
        elseif key == "note" then av, bv = a.note:lower(), b.note:lower()
        elseif key == "onote" then av, bv = a.officerNote:lower(), b.officerNote:lower()
        else av, bv = a.name:lower(), b.name:lower() end
        
        -- Fallback: if values are equal, sort alphabetically by name
        if av == bv then return a.name:lower() < b.name:lower() end
        if rev then return av > bv else return av < bv end
    end)
    return rows
end
