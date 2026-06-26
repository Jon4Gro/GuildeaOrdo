-- GuildeaOrdo UI Main
GuildeaOrdo = GuildeaOrdo or {}
GuildeaOrdo.UI = {}
local UI    = GuildeaOrdo.UI
local addon = GuildeaOrdo

-- =========================================================
-- Constants & UI State
-- =========================================================
UI.ROW_HEIGHT = 14
UI.ROW_COUNT  = 20

UI.activeView = "LOG"
UI.rosterOfflineDaysSearch = ""
UI.logSearchText = ""
UI.showLineNumbers = true
UI.rosterShowOffline = true
UI.rosterPlayerSearch = ""
UI.rosterRankSearch = ""
UI.rosterNoteSearch = ""
UI.rosterSortBy = "name"
UI.rosterSortReverse = false
UI.groupAltsWithMain = false
UI.macroSelectedChannel = "GUILD"
UI.typeFilters = { SEEN = true, JOIN = true, LEAVE = true, PROMOTE = true, DEMOTE = true, NOTE = true, ONOTE = true, LEVEL = false }
UI.CHANNEL_OPTIONS = { "1","2","3","4","5","6","7","8","9", "GUILD","OFFICER","SAY","PARTY","RAID","YELL" }

UI.COL_DEFS = {
    { key = "lvl",    label = "Lvl",         sort = "level",    width = 18  },
    { key = "name",   label = "Name",        sort = "name",     width = 90  },
    { key = "online", label = "Last Online", sort = "online",   width = 80  },
    { key = "join",   label = "Join Date",   sort = "joinDate", width = 80  },
    { key = "rank",   label = "Rank",        sort = "rank",     width = 80  },
    { key = "note",   label = "Note",        sort = "note",     width = 154 },
    { key = "onote",  label = "Officer Note",sort = "onote",    width = 154 },
}
UI.COL_GAP = 4
UI.ROSTER_COLS = { {key="lvl",width=18}, {key="name",width=94}, {key="online",width=71}, {key="join",width=71}, {key="rank",width=80}, {key="note",width=210}, {key="onote",width=210} }
UI.RANKS_COLS  = { {key="name",width=100}, {key="rank",width=70}, {key="online",width=70}, {key="note",width=100}, {key="onote",width=160} }

UI.BACKDROP = {
    bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 },
}
UI.PANEL_BACKDROP = {
    bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 },
}
UI.TYPE_COLOR = { SEEN="|cffaaaaaa", JOIN="|cff44ff44", LEAVE="|cffff5555", PROMOTE="|cffaaff66", DEMOTE="|cffff8800", NOTE="|cffff77ff", ONOTE="|cffcc88ff", LEVEL="|cff66ccff" }
UI.TYPE_LABEL = { SEEN="Initial", JOIN="Joined", LEAVE="Left", PROMOTE="Promoted", DEMOTE="Demoted", NOTE="Public Note", ONOTE="Officer Note", LEVEL="Leveled" }
UI.TYPE_ORDER = { "JOIN", "LEAVE", "PROMOTE", "DEMOTE", "NOTE", "ONOTE", "SEEN" }
UI.CLASS_COLOR = { DEATHKNIGHT="|cffc41f3b", DRUID="|cffff7d0a", HUNTER="|cffabd473", MAGE="|cff69ccf0", PALADIN="|cfff58cba", PRIEST="|cffffffff", ROGUE="|cfffff569", SHAMAN="|cff0070de", WARLOCK="|cff9482c9", WARRIOR="|cffc79c6e" }

UI.frame = nil

-- =========================================================
-- Missing Core API Integration
-- =========================================================
function addon:IsWhitelisted(name)
    local g = self:GetCurrentGuild()
    return g and g.whitelist and g.whitelist[UI.lowerSafe(name)] or false
end

function addon:ToggleWhitelist(name)
    local g = self:GetCurrentGuild()
    if not g then return end
    g.whitelist = g.whitelist or {}
    local lower = UI.lowerSafe(name)
    g.whitelist[lower] = not g.whitelist[lower]
end

-- =========================================================
-- Helpers
-- =========================================================
function UI.colorize(typeKey, text) return (UI.TYPE_COLOR[typeKey] or "|cffffffff") .. text .. "|r" end
function UI.lowerSafe(s) return (s or ""):lower() end
function UI.fmtDateLong(epoch) return epoch and date("%d %b '%y %H:%M", epoch) or "?" end

function UI.fmtSince(epoch)
    if not epoch then return "?" end
    local d = time() - epoch
    if d < 60     then return "online" end
    if d < 3600   then return ("%d min"):format(math.floor(d / 60)) end
    if d < 86400  then return ("%d hrs"):format(math.floor(d / 3600)) end
    if d < 604800 then return ("%d days"):format(math.floor(d / 86400)) end
    if d < 2592000 then return ("%d wks"):format(math.floor(d / 604800)) end
    if d < 31536000 then return ("%d mos"):format(math.floor(d / 2592000)) end
    return ("%d yrs"):format(math.floor(d / 31536000))
end

function UI.lastSeenColor(epoch, online)
    if online then return "|cff44ff44" end
    if not epoch then return "|cff888888" end
    local d = time() - epoch
    if d < 86400   then return "|cff99ff99" end
    if d < 604800  then return "|cffffffff" end
    if d < 2592000 then return "|cffffff66" end
    if d < 7776000 then return "|cffffaa00" end
    return "|cffff4444"
end

function UI.classColor(classFile, name) return (UI.CLASS_COLOR[classFile or ""] or "|cffeeeeee") .. (name or "?") .. "|r" end

function UI.ProcessBatch(actionName, list, actionFunc)
    if not list or #list == 0 then print("|cff00ff00GuildeaOrdo:|r No members in selection."); return end
    local bSize = math.max(1, tonumber((GuildeaOrdoDB and GuildeaOrdoDB.batchSize) or 2))
    local total, currentIdx, batchNum = #list, 1, 1
    local processor = CreateFrame("Frame")
    local timer = 0
    processor:SetScript("OnUpdate", function(self, elapsed)
        timer = timer + elapsed
        if timer >= 1.0 or currentIdx == 1 then
            timer = 0
            local endIdx = math.min(currentIdx + bSize - 1, total)
            for i = currentIdx, endIdx do
                if list[i] and list[i].name then actionFunc(list[i].name) end
            end
            print("|cff00ff00GuildeaOrdo:|r " .. actionName .. " Batch " .. batchNum .. " / " .. math.ceil(total / bSize) .. " Done")
            currentIdx, batchNum = endIdx + 1, batchNum + 1
            if currentIdx > total then
                self:SetScript("OnUpdate", nil)
                print("|cff00ff00GuildeaOrdo:|r All " .. actionName .. " operations completed.")
                if GuildeaOrdo.RequestRosterAfterAction then GuildeaOrdo:RequestRosterAfterAction() else GuildRoster() end
            end
        end
    end)
end

-- =========================================================
-- Build Frame
-- =========================================================
local function build()
    if UI.frame then return UI.frame end

    local f = CreateFrame("Frame", "GuildeaOrdoMainFrame", UIParent)
    f:SetSize(900, 480)
    f:SetPoint("CENTER")
    f:SetBackdrop(UI.BACKDROP)
    f:SetBackdropColor(0, 0, 0, 1)
    f:SetMovable(true); f:EnableMouse(true); f:SetClampedToScreen(true); f:SetFrameStrata("HIGH")
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:Hide()

    -- Header
    f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    f.title:SetPoint("TOPLEFT", 18, -18)
    f.title:SetText("|cFFFFCC00GuildeaOrdo|r")
    f.subtitle = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.subtitle:SetPoint("RIGHT", f.title ,"RIGHT",330, 0)
    f.rightHeader = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.rightHeader:SetPoint("TOPRIGHT", -34, -22); f.rightHeader:SetJustifyH("RIGHT")
    f.rrightHeader = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.rrightHeader:SetPoint("TOPRIGHT", -34, -39); f.rrightHeader:SetJustifyH("RIGHT")

    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", 2, 2)

    -- Tabs
    f.tabButtons = {}
    local function makeViewBtn(label, viewKey)
        local b = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        b:SetSize(86, 22)
        b:SetText("|cFFFFCC00" .. label .. "|r")
        if b:GetFontString() then b:GetFontString():SetTextColor(1, 0.8, 0) end
        b:SetScript("OnClick", function(self)
            UI.activeView = viewKey
            for _, btn in pairs(f.tabButtons) do btn:UnlockHighlight(); if btn:GetFontString() then btn:GetFontString():SetTextColor(1, 0.8, 0) end end
            self:LockHighlight()
            UI:Refresh()
        end)
        f.tabButtons[viewKey] = b
        return b
    end
    f.tabLog = makeViewBtn("Log", "LOG"); f.tabLog:SetPoint("TOPLEFT", 16, -38)
    f.tabRoster = makeViewBtn("Roster", "ROSTER"); f.tabRoster:SetPoint("TOPLEFT", f.tabLog, "TOPRIGHT", 4, 0)
    f.tabAlts = makeViewBtn("Alts", "ALTS"); f.tabAlts:SetPoint("TOPLEFT", f.tabRoster, "TOPRIGHT", 4, 0)
    f.tabMacros = makeViewBtn("Macros", "MACROS"); f.tabMacros:SetPoint("TOPLEFT", f.tabAlts, "TOPRIGHT", 4, 0)
    f.tabRanks = makeViewBtn("Ranks", "RANKS"); f.tabRanks:SetPoint("TOPLEFT", f.tabMacros, "TOPRIGHT", 4, 0)
    f.tabSettings = makeViewBtn("Settings", "SETTINGS"); f.tabSettings:SetPoint("TOPLEFT", f.tabRanks, "TOPRIGHT", 4, 0)

    -- Module Builders
    if UI.BuildLog then UI.BuildLog(f) end
    if UI.BuildRoster then UI.BuildRoster(f) end
    if UI.BuildAlts then UI.BuildAlts(f) end
    if UI.BuildMacros then UI.BuildMacros(f) end
    if UI.BuildRanks then UI.BuildRanks(f) end
    if UI.BuildSettings then UI.BuildSettings(f) end

    -- Column Headers (Shared)
    f.colHeader = CreateFrame("Frame", nil, f)
    f.colHeader:SetHeight(20); f.colHeader:SetPoint("TOPLEFT", 16, -106); f.colHeader:SetPoint("RIGHT", -18, 0)
    f.colHeaderBtns = {}
    local prevHeader
    for _, def in ipairs(UI.COL_DEFS) do
        local b = CreateFrame("Button", nil, f.colHeader)
        b:SetSize(def.width, 20)
        b:SetNormalFontObject("GameFontNormal"); b:SetHighlightFontObject("GameFontHighlight")
        b:SetText(def.label)
        b:GetFontString():SetJustifyH("LEFT"); b:GetFontString():ClearAllPoints()
        b:GetFontString():SetPoint("LEFT", b, "LEFT", 0, 0); b:GetFontString():SetWidth(def.width)
        b:SetScript("OnClick", function()
            if UI.rosterSortBy == def.sort then UI.rosterSortReverse = not UI.rosterSortReverse
            else UI.rosterSortBy = def.sort; UI.rosterSortReverse = false end
            UI:Refresh()
        end)
        if prevHeader then b:SetPoint("LEFT", prevHeader, "RIGHT", UI.COL_GAP, 0) else b:SetPoint("LEFT", 0, 0) end
        f.colHeaderBtns[def.key] = b
        prevHeader = b
    end

    -- List Panel (Shared)
    f.listPanel = CreateFrame("Frame", nil, f)
    f.listPanel:SetPoint("TOPLEFT", 16, -160); f.listPanel:SetPoint("BOTTOMRIGHT", -180, 56)
    f.listPanel:SetBackdrop(UI.PANEL_BACKDROP); f.listPanel:SetBackdropColor(0, 0, 0, 0.6)

    f.scroll = CreateFrame("ScrollFrame", "GuildeaOrdoListScroll", f.listPanel, "FauxScrollFrameTemplate")
    f.scroll:SetPoint("TOPLEFT", 6, -6); f.scroll:SetPoint("BOTTOMRIGHT", -28, 6)
    f.scroll:SetScript("OnVerticalScroll", function(self, offset)
        FauxScrollFrame_OnVerticalScroll(self, offset, UI.ROW_HEIGHT, function() UI:Refresh() end)
    end)

    f.rows, f.rowCells, f.rowMacroBtns, f.rowClickBtns = {}, {}, {}, {}
    for i = 1, UI.ROW_COUNT do
        local rowY = -((i - 1) * UI.ROW_HEIGHT) - 2
        local row = f.listPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row:SetPoint("TOPLEFT", f.scroll, "TOPLEFT", 4, rowY)
        row:SetPoint("RIGHT", f.scroll, "RIGHT", -4, 0); row:SetHeight(UI.ROW_HEIGHT); row:SetJustifyH("LEFT")
        f.rows[i] = row

        local cells, prevCell = {}, nil
        for _, def in ipairs(UI.COL_DEFS) do
            local fs = f.listPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            fs:SetWidth(def.width); fs:SetHeight(UI.ROW_HEIGHT); fs:SetJustifyH("LEFT"); fs:SetWordWrap(false)
            if prevCell then fs:SetPoint("LEFT", prevCell, "RIGHT", UI.COL_GAP, 0) else fs:SetPoint("TOPLEFT", f.scroll, "TOPLEFT", 4, rowY) end
            cells[def.key] = fs
            prevCell = fs
        end
        f.rowCells[i] = cells

        local function mkBtn(w, txt, anchorBtn)
            local b = CreateFrame("Button", nil, f.listPanel, "UIPanelButtonTemplate")
            b:SetSize(w, UI.ROW_HEIGHT - 1); b:SetText("|cFFFFCC00"..txt.."|r"); b:Hide()
            if anchorBtn then b:SetPoint("RIGHT", anchorBtn, "LEFT", -2, 0) else b:SetPoint("TOPRIGHT", f.scroll, "TOPRIGHT", -4, rowY) end
            return b
        end
        local delBtn  = mkBtn(36, "Del")
        local sendBtn = mkBtn(40, "Send", delBtn)
        local setBtn  = mkBtn(36, "Set", sendBtn)
        local editBtn = mkBtn(40, "Edit", setBtn)
        f.rowMacroBtns[i] = { send = sendBtn, del = delBtn, edit = editBtn, set = setBtn }

        local cb = CreateFrame("Button", nil, f.listPanel)
        cb:SetPoint("TOPLEFT", f.scroll, "TOPLEFT", 2, rowY); cb:SetPoint("TOPRIGHT", f.scroll, "TOPRIGHT", -2, rowY)
        cb:SetHeight(UI.ROW_HEIGHT); cb:RegisterForClicks("LeftButtonUp", "RightButtonUp"); cb:EnableMouse(true); cb:Hide()
        local hl = cb:CreateTexture(nil, "HIGHLIGHT"); hl:SetTexture("Interface\\Buttons\\WHITE8X8"); hl:SetVertexColor(1,1,1,0.08); hl:SetAllPoints(cb)
        f.rowClickBtns[i] = cb
    end

    f.status = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.status:SetPoint("BOTTOMLEFT", 16, 14)

    _G["GuildeaOrdoMainFrame"] = f
    table.insert(UISpecialFrames, "GuildeaOrdoMainFrame")
    if GuildFrame then
        GuildFrame:HookScript("OnShow", function() if GuildeaOrdoCharDB and GuildeaOrdoCharDB.openWithGuild then if not f:IsShown() then UI:Show() end end end)
        GuildFrame:HookScript("OnHide", function() if GuildeaOrdoCharDB and GuildeaOrdoCharDB.closeWithGuild then if f:IsShown() then UI:Hide() end end end)
    end
    UI.frame = f
    return f
end

-- =========================================================
-- Visibility and Master Rendering Loop
-- =========================================================
local function setVis(w, vis) if w then if vis then w:Show() else w:Hide() end end end

function UI:Refresh()
    local f = UI.frame
    if not f or not f:IsShown() then return end

    local logMode      = (UI.activeView == "LOG")
    local rosterMode   = (UI.activeView == "ROSTER")
    local altsMode     = (UI.activeView == "ALTS")
    local macrosMode   = (UI.activeView == "MACROS")
    local ranksMode    = (UI.activeView == "RANKS")
    local settingsMode = (UI.activeView == "SETTINGS")

    setVis(f.colHeader, rosterMode or ranksMode)
    for _, def in ipairs(UI.COL_DEFS) do
        f.colHeaderBtns[def.key]:Hide()
        for i = 1, UI.ROW_COUNT do f.rowCells[i][def.key]:Hide() end
    end

    local activeCols = rosterMode and UI.ROSTER_COLS or (ranksMode and UI.RANKS_COLS or nil)
    if activeCols then
        local prevHeader
        for _, col in ipairs(activeCols) do
            local btn = f.colHeaderBtns[col.key]
            if btn then
                btn:SetWidth(col.width)
                if btn:GetFontString() then btn:GetFontString():SetWidth(col.width) end
                btn:ClearAllPoints()
                if prevHeader then btn:SetPoint("LEFT", prevHeader, "RIGHT", UI.COL_GAP, 0) else btn:SetPoint("LEFT", f.colHeader, "LEFT", 0, 0) end
                btn:Show(); prevHeader = btn
            end
        end
        for i = 1, UI.ROW_COUNT do
            local prevCell
            for _, col in ipairs(activeCols) do
                local cell = f.rowCells[i][col.key]
                if cell then
                    cell:SetWidth(col.width); cell:ClearAllPoints()
                    if prevCell then cell:SetPoint("LEFT", prevCell, "RIGHT", UI.COL_GAP, 0) else cell:SetPoint("TOPLEFT", f.scroll, "TOPLEFT", 4, -((i - 1) * UI.ROW_HEIGHT) - 2) end
                    prevCell = cell
                end
            end
        end
    end

    if settingsMode then f.listPanel:Hide() else
        f.listPanel:Show(); f.listPanel:ClearAllPoints()
        f.listPanel:SetPoint("TOPLEFT", 16, macrosMode and -200 or -130)
        f.listPanel:SetPoint("BOTTOMRIGHT", logMode and -180 or (ranksMode and -330 or -18), 56)
    end

    setVis(f.logSearch, logMode); setVis(f.logSearchLabel, logMode); setVis(f.filterPanel, logMode); setVis(f.numberedCB, logMode); setVis(f.numberedLabel, logMode); setVis(f.clearLogBtn, logMode)
    setVis(f.rosterShowOfflineCB, rosterMode); setVis(f.rosterShowOfflineLabel, rosterMode); setVis(f.rosterPSearch, rosterMode); setVis(f.rosterPSearchLabel, rosterMode); setVis(f.rosterRankSearch, rosterMode); setVis(f.rosterRankSearchLabel, rosterMode); setVis(f.rosterNSearch, rosterMode); setVis(f.rosterNSearchLabel, rosterMode); setVis(f.groupAltsCB, rosterMode); setVis(f.groupAltsLabel, rosterMode); setVis(f.rosterONoteEmptyBtn, rosterMode or logMode); setVis(f.rosterOffDaysInput, rosterMode); setVis(f.rosterOffDaysLabel, rosterMode); setVis(f.rosterMassKickBtn, rosterMode)
    setVis(f.altInputAlt, altsMode); setVis(f.altInputMain, altsMode); setVis(f.altInputAltLabel, altsMode); setVis(f.altInputMainLabel, altsMode); setVis(f.altBtnSet, altsMode); setVis(f.altBtnUnset, altsMode)
    setVis(f.macroMsgLabel, macrosMode); setVis(f.macroMsgBg, macrosMode); setVis(f.macroChanLabel, macrosMode); setVis(f.macroSaveBtn, macrosMode); setVis(f.macroSpamCB, macrosMode); setVis(f.macroSpamLabel, macrosMode); setVis(f.macroSpamInterval, macrosMode); setVis(f.macroSpamMinLabel, macrosMode); setVis(f.macroSpamTotalLabel, macrosMode); setVis(f.macroSpamTotal, macrosMode); setVis(f.macroSpamTotalMinLabel, macrosMode)
    for _, b in pairs(f.macroChanBtns or {}) do setVis(b, macrosMode) end
    
    setVis(f.ranksConfigPanel, ranksMode)
    if ranksMode then
        local numRanks = GuildControlGetNumRanks() or 0
        for i = 1, 10 do
            local r = f.rankRows[i]
            if r then if i <= numRanks and i > 1 then r.frame:Show(); r.nameStr:SetText(GuildControlGetRankName(i)) else r.frame:Hide() end end
        end
    end

    setVis(f.slashCmdLabel, settingsMode); setVis(f.slashCmdText, settingsMode); setVis(f.batchSizeLabel, settingsMode); setVis(f.batchSizeInput, settingsMode); setVis(f.openWithGuildCB, settingsMode); setVis(f.openWithGuildLabel, settingsMode); setVis(f.closeWithGuildCB, settingsMode); setVis(f.closeWithGuildLabel, settingsMode); setVis(f.bracketInfoLabel, settingsMode); setVis(f.bLeftLbl, settingsMode); setVis(f.bLeft, settingsMode); setVis(f.bRightLbl, settingsMode); setVis(f.bRight, settingsMode); setVis(f.showMinimapCB, settingsMode); setVis(f.showMinimapLabel, settingsMode); setVis(f.minimapCtrlLabel, settingsMode); setVis(f.minimapRotSlider, settingsMode); setVis(f.minimapRotLabel, settingsMode); setVis(f.minimapRotVal, settingsMode); setVis(f.minimapRotLow, settingsMode); setVis(f.minimapRotHigh, settingsMode); setVis(f.minimapDistSlider, settingsMode); setVis(f.minimapDistLabel, settingsMode); setVis(f.minimapDistVal, settingsMode); setVis(f.minimapDistLow, settingsMode); setVis(f.minimapDistHigh, settingsMode); setVis(f.autoInvLabel, settingsMode); setVis(f.autoInvCB, settingsMode); setVis(f.autoInvCBLabel, settingsMode); setVis(f.autoInvBg, settingsMode); setVis(f.aiPhraseBg, settingsMode); setVis(f.aiPhraseLbl, settingsMode); setVis(f.aiOnBg, settingsMode); setVis(f.aiOnLbl, settingsMode); setVis(f.aiOffBg, settingsMode); setVis(f.aiOffLbl, settingsMode); setVis(f.aiMinLvlBg, settingsMode); setVis(f.aiMinLvlLbl, settingsMode); setVis(f.aiReplyLowBg, settingsMode); setVis(f.aiReplyLowLbl, settingsMode); setVis(f.groupInviteLabel, settingsMode); setVis(f.groupInviteCheck, settingsMode); setVis(f.groupInviteEditBox, settingsMode); setVis(f.groupInviteEditBoxLabel, settingsMode); setVis(f.groupInvitePermCheck, settingsMode); setVis(f.groupInviteMinLabel, settingsMode); setVis(f.groupInviteMinutes, settingsMode); setVis(f.groupInviteBg, settingsMode); setVis(f.shareBlacklistBtn, settingsMode); setVis(f.autoBanLeaveCB, settingsMode); setVis(f.autoBanLeaveLabel, settingsMode); setVis(f.blacklistBtn, settingsMode)

    if settingsMode and GuildeaOrdoDB then
        if not f.batchSizeInput:HasFocus() then f.batchSizeInput:SetText(tostring(GuildeaOrdoDB.batchSize or 2)) end
            if f.bLeft and not f.bLeft:HasFocus() then f.bLeft:SetText(GuildeaOrdoDB.bracketLeft or "[") end
                if f.bRight and not f.bRight:HasFocus() then f.bRight:SetText(GuildeaOrdoDB.bracketRight or "]") end
                            if GuildeaOrdoCharDB.autoInvite then
            local conf = GuildeaOrdoCharDB.autoInvite
            f.autoInvCB:SetChecked(conf.enabled)
            if not f.aiPhrase:HasFocus() then f.aiPhrase:SetText(conf.phrase or "") end
            if not f.aiOn:HasFocus() then f.aiOn:SetText(conf.replyOn or "") end
            if not f.aiOff:HasFocus() then f.aiOff:SetText(conf.replyOff or "") end
            if not f.aiMinLvl:HasFocus() then f.aiMinLvl:SetText(tostring(conf.minLvl or 1)) end
            if not f.aiReplyLow:HasFocus() then f.aiReplyLow:SetText(conf.replyLow or "") end
            if f.groupInviteMinutes and not f.groupInviteMinutes:HasFocus() then f.groupInviteMinutes:SetText(tostring(conf.groupMinutes or 15)) end
        end
    end

    if macrosMode then
        if f.macroSpamCB then f.macroSpamCB:SetChecked(addon.spamActive) end
        if f.macroSpamInterval and not f.macroSpamInterval:HasFocus() then f.macroSpamInterval:SetText(tostring(addon.spamInterval or 5)) end
        if f.macroSpamTotal and not f.macroSpamTotal:HasFocus() then local t = (GuildeaOrdoDB and GuildeaOrdoDB.spamTotalMinutes) or addon.spamTotalLimit or 0; f.macroSpamTotal:SetText(tostring(t)); addon.spamTotalLimit = t end
    end

    for view, b in pairs(f.tabButtons) do if view == UI.activeView then b:LockHighlight() else b:UnlockHighlight() end end

    local key = addon:GetCurrentGuildKey()
    local guildLabel = key and key:gsub("::", " / ") or "(not in a guild)"
    if logMode then f.subtitle:SetText("|cFFFFCC00Guild Logs|r   " .. guildLabel)
    elseif rosterMode then f.subtitle:SetText("|cFFFFCC00Guild Roster|r   " .. guildLabel)
    elseif macrosMode then f.subtitle:SetText("|cFFFFCC00Saved Macros|r   Account-wide")
    elseif ranksMode then f.subtitle:SetText("|cFFFFCC00Rank Up Settings|r   " .. guildLabel)
    elseif settingsMode then f.subtitle:SetText("|cFFFFCC00Auto Settings Guild/Group Invites and more|r")
    else f.subtitle:SetText("|cFFFFCC00Alts|r   " .. guildLabel) end

    local data, total, onlineCount = {}, 0, 0
    if settingsMode then
        f.rightHeader:SetText(("Version |cffffffff%s|r"):format(addon.version or "?")); f.rightHeader:Show(); f.rrightHeader:Hide()
        if GuildeaOrdoCharDB then f.openWithGuildCB:SetChecked(GuildeaOrdoCharDB.openWithGuild); f.closeWithGuildCB:SetChecked(GuildeaOrdoCharDB.closeWithGuild) end
        if f.showMinimapCB then f.showMinimapCB:SetChecked(GuildeaOrdoDB.showMinimapButton ~= false) end
        if f.autoBanLeaveCB then f.autoBanLeaveCB:SetChecked(GuildeaOrdoDB.autoBanOnLeave == true) end
        if f.minimapRotSlider then local r = GuildeaOrdoDB.minimapRotation or 0; f.minimapRotSlider:SetValue(r); if f.minimapRotVal then f.minimapRotVal:SetText(tostring(r)) end end
        if f.minimapDistSlider then local d = math.max(20, math.min(240, GuildeaOrdoDB.minimapDistance or 80)); if GuildeaOrdoDB then GuildeaOrdoDB.minimapDistance = d end; f.minimapDistSlider:SetValue(d); if f.minimapDistVal then f.minimapDistVal:SetText(tostring(d)) end end
    elseif logMode then data, total = UI.CollectLogRows(); f.rightHeader:SetText(("Total Entries: |cffffffff%d|r"):format(total))
    elseif rosterMode then data, onlineCount, total = UI.CollectRosterRows(); addon.RosterRowsCache = data; f.rightHeader:SetText(("|cffffffff%d|r / %d Online"):format(onlineCount, total))
    elseif ranksMode then data = UI.CollectRanksRows(); addon.RanksRowsCache = data; f.rightHeader:SetText(("|cffffffff%d|r Candidates matching criteria"):format(#data))
    elseif macrosMode then data = UI.CollectMacrosRows(); local filtered = {}; for _, m in ipairs(data) do if m.channel == UI.macroSelectedChannel then table.insert(filtered, m) end end; data = filtered; f.rightHeader:SetText(("|cffffffff%d|r macros  -  channel: |cffffcc00%s|r"):format(#data, UI.macroSelectedChannel))
    else data = UI.CollectAltsRows(); f.rightHeader:SetText(("|cffffffff%d|r mappings"):format(#data)) end

    if rosterMode then f.rrightHeader:SetText(("|cffffffff%d|r displayed members"):format(#data)); f.rrightHeader:Show() else f.rrightHeader:SetText(""); f.rrightHeader:Hide() end

    if macrosMode then
        for opt, b in pairs(f.macroChanBtns) do if opt == UI.macroSelectedChannel then b:LockHighlight() else b:UnlockHighlight() end; if b:GetFontString() then b:GetFontString():SetTextColor(1, 0.8, 0) end end
    end

    if not settingsMode then
        FauxScrollFrame_Update(f.scroll, #data, UI.ROW_COUNT, UI.ROW_HEIGHT)
        local offset = FauxScrollFrame_GetOffset(f.scroll)

        if rosterMode or ranksMode then
            local mark = UI.rosterSortReverse and "  v" or "  ^"
            for _, def in ipairs(UI.COL_DEFS) do
                f.colHeaderBtns[def.key]:SetText((UI.rosterSortBy == def.sort and def.label .. mark or def.label))
                if f.colHeaderBtns[def.key]:GetFontString() then f.colHeaderBtns[def.key]:GetFontString():SetTextColor(1, 0.8, 0) end
            end
        end

        for i = 1, UI.ROW_COUNT do
            local idx = i + offset
            local item = data[idx]
            local row = f.rows[i]
            local cells = f.rowCells[i]
            local btns = f.rowMacroBtns[i]
            local clickBtn = f.rowClickBtns[i]

            local function wipeRow()
                row:SetText(""); row:Hide()
                for _, c in pairs(cells) do c:SetText(""); c:Hide() end
                btns.send:Hide(); btns.del:Hide(); btns.edit:Hide(); btns.set:Hide(); clickBtn:Hide(); clickBtn:SetScript("OnClick", nil)
            end

            wipeRow()

            if item then
                if logMode then
                    row:SetPoint("RIGHT", f.scroll, "RIGHT", -4, 0)
                    local e, n = item.entry, item.n
                    local prefix = UI.showLineNumbers and ("|cff888888%4d)|r "):format(n) or ""
                    row:SetText(("%s|cffaaaaaa%s|r  %s  |cffffffff%s|r%s"):format(prefix, UI.fmtDateLong(e.t), UI.colorize(e.type, UI.TYPE_LABEL[e.type] or e.type), e.who or "?", e.details and (" - " .. e.details) or ""))
                    row:Show()
                elseif rosterMode or ranksMode then
                    local lvlTxt = (item.level and item.level > 0) and tostring(item.level) or "?"
                    if cells.lvl then cells.lvl:SetText("|cffffffff" .. lvlTxt .. "|r") end
                    
                    local mainTag = item.main and "  |cffaaaaff(alt)|r" or ""
                    if not item.main then
                        local g = addon:GetCurrentGuild()
                        if g and g.alts then
                            for _, m in pairs(g.alts) do if m == item.name then mainTag = "  |cffffcc00<M>|r"; break end end
                        end
                    end
                    
                    -- Wrapped strictly here to prevent missing API crashes
                    local whiteTag = ""
                    if addon.IsWhitelisted and addon:IsWhitelisted(item.name) then whiteTag = " |cff00ff00[W]|r" end
                    
                    if cells.name then cells.name:SetText(UI.classColor(item.classFile, item.name) .. mainTag .. whiteTag) end
                    if cells.online then cells.online:SetText(UI.lastSeenColor(item.lastSeen, item.online) .. (item.online and "Online" or UI.fmtSince(item.lastSeen)) .. "|r") end
                    if cells.join then cells.join:SetText(item.joinDate and ("|cffcccccc" .. item.joinDate .. "|r") or "|cff666666?|r") end
                    if cells.rank then cells.rank:SetText(item.rank or "") end
                    if cells.note then cells.note:SetText(item.note or "") end
                    if cells.onote then cells.onote:SetText(item.officerNote or "") end
                    
                    if activeCols then for _, col in ipairs(activeCols) do if cells[col.key] then cells[col.key]:Show() end end end
                    
                    local rowName = item.name
                    clickBtn:SetScript("OnClick", function(_, button)
                    if button == "RightButton" and UI.ShowRosterContextMenu then UI.ShowRosterContextMenu(rowName)
                        elseif button == "LeftButton" and addon.ShowMemberDetail then addon:ShowMemberDetail(rowName) end
                            end)
                    clickBtn:Show()
                elseif altsMode then
                    row:SetPoint("RIGHT", f.scroll, "RIGHT", -4, 0)
                    row:SetText(("|cffffffff%s|r  |cff888888is alt of|r  |cffffcc00%s|r"):format(item.alt, item.main))
                    row:Show()
                elseif macrosMode then
                    row:SetPoint("RIGHT", btns.edit, "LEFT", -6, 0)
                    local isSpam = addon.spamMacros and addon.spamMacros[item.index]
                    row:SetText(item.text .. (isSpam and " |cff00ff00[SPAM]|r" or ""))
                    row:Show()
                    btns.send:Show(); btns.del:Show(); btns.edit:Show(); btns.set:Show()
                    btns.set:SetText(isSpam and "|cff00ff00On|r" or "|cFFFFCC00Set|r")
                    for _, b in ipairs({"send", "del", "edit", "set"}) do if btns[b]:GetFontString() then btns[b]:GetFontString():SetTextColor(1, 0.8, 0) end end
                    local idx, txt, chan = item.index, item.text, item.channel
                    btns.send:SetScript("OnClick", function() addon:SendMacro(idx) end)
                    btns.del:SetScript("OnClick", function()
                    addon:RemoveMacro(idx)
                    if addon.spamMacros then
                        local newSpam = {}
                        for oldIdx, active in pairs(addon.spamMacros) do
                            if active then if oldIdx < idx then newSpam[oldIdx] = true elseif oldIdx > idx then newSpam[oldIdx - 1] = true end end
                            end
                            addon.spamMacros = newSpam
                            local hasActive = false
                            for _, v in pairs(addon.spamMacros) do if v then hasActive = true; break end end
                                if not hasActive and addon.spamActive then
                                    addon.spamActive = false
                                    if f.macroSpamCB then f.macroSpamCB:SetChecked(false) end
                                    print("|cFFFFCC00GuildeaOrdo|r: Macro Spam Ended (All macros removed).")
                                    end
                                end
                    UI:Refresh()
                    end)
                    btns.edit:SetScript("OnClick", function()
                        if (f.macroMsg:GetText() or "") == "" then
                            f.macroMsg:SetText(txt); UI.macroSelectedChannel = chan; addon.editingMacroIndex = idx; UI:Refresh()
                        else print("|cFFFFCC00GuildeaOrdo|r: Clear the message box first to edit.") end
                    end)
                    btns.set:SetScript("OnClick", function()
                    addon.spamMacros = addon.spamMacros or {}; addon.spamMacros[idx] = not addon.spamMacros[idx]
                    if addon.spamMacros[idx] then
                        print("|cFFFFCC00GuildeaOrdo|r: Macro added to spam rotation.")
                        else
                            print("|cFFFFCC00GuildeaOrdo|r: Macro removed from spam rotation.")
                            local hasActive = false
                            for _, v in pairs(addon.spamMacros) do if v then hasActive = true; break end end
                                if not hasActive and addon.spamActive then
                                addon.spamActive = false
                                if f.macroSpamCB then f.macroSpamCB:SetChecked(false) end
                                print("|cFFFFCC00GuildeaOrdo|r: Macro Spam Ended (No active macros).")
                                end
                        end
                    UI:Refresh()
                    end)
                end
            end
        end
    end
end

function UI:RefreshIfShown() if UI.frame and UI.frame:IsShown() then UI:Refresh() end end
function UI:Toggle() local f = build(); if f:IsShown() then UI:Hide() else UI:Show() end end
function UI:Show() local f = build(); f:Show(); UI:Refresh() end
function UI:Hide() if UI.frame then UI.frame:Hide() end; if UI.HideBlacklistDetail then UI:HideBlacklistDetail() end; if GuildeaOrdoBlacklistFrame and GuildeaOrdoBlacklistFrame:IsShown() then GuildeaOrdoBlacklistFrame:Hide() end end
