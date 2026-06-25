-- GildeaOrdo Blacklist UI Module
local addon = GildeaOrdo
local UI    = addon.UI

local blacklistFrame
local blacklistDetailFrame
local blRows = {}
local BL_ROW_HEIGHT = 18
local MAX_BL_ROWS = 25
local selectedBlacklistName = nil

local function positionBlacklistWindow(f)
    if UI.frame and UI.frame:IsShown() then
        f:ClearAllPoints(); f:SetPoint("TOPLEFT", UI.frame, "TOPRIGHT", 6, 0)
        local h = (UI.frame:GetHeight() or 300) - 170; if h < 260 then h = 260 end
        f:SetHeight(h); f:SetWidth(390)
    else f:ClearAllPoints(); f:SetPoint("CENTER", UIParent, "CENTER", 0, 60) end
    if blacklistDetailFrame and blacklistDetailFrame:IsShown() then UI:ShowBlacklistDetail(selectedBlacklistName) end
end

local function buildBlacklistWindow()
    if blacklistFrame then return blacklistFrame end
    local f = CreateFrame("Frame", "GildeaOrdoBlacklistFrame", UIParent)
    f:SetSize(390, 380); f:SetPoint("CENTER", 0, 50); f:SetBackdrop(UI.BACKDROP); f:SetBackdropColor(0, 0, 0, 1); f:SetMovable(true); f:EnableMouse(true); f:SetClampedToScreen(true); f:SetFrameStrata("HIGH")
    f:RegisterForDrag("LeftButton"); f:SetScript("OnDragStart", f.StartMoving); f:SetScript("OnDragStop", f.StopMovingOrSizing); f:Hide()

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge"); title:SetPoint("TOPLEFT", 16, -16); title:SetText("|cFFFFCC00Blacklist|r  |cffaaaaaa(Auto Guild + Group Invite)|r")
    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton"); close:SetPoint("TOPRIGHT", 2, 2)

    local nameLabel = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); nameLabel:SetPoint("TOPLEFT", 21, -48); nameLabel:SetText("Player Name")
    local nameInput = CreateFrame("EditBox", "GildeaOrdoBLNameInput", f, "InputBoxTemplate")
    nameInput:SetSize(180, 20); nameInput:SetPoint("TOPLEFT", nameLabel, "BOTTOMLEFT", 2, -2); nameInput:SetAutoFocus(false)
    nameInput:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    nameInput:SetScript("OnEnterPressed", function(self) local n = self:GetText(); if n and n ~= "" then addon:AddToBlacklist(n); self:SetText("") end; self:ClearFocus(); UI:RefreshBlacklistWindow() end)
    nameInput:SetScript("OnTextChanged", function(self) UI:RefreshBlacklistWindow() end)

    local addBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate"); addBtn:SetSize(60, 22); addBtn:SetText("|cFFFFCC00Add|r"); if addBtn:GetFontString() then addBtn:GetFontString():SetTextColor(1, 0.8, 0) end
    addBtn:SetPoint("LEFT", nameInput, "RIGHT", 8, 0)
    addBtn:SetScript("OnClick", function() local n = nameInput:GetText(); if n and n ~= "" then addon:AddToBlacklist(n); nameInput:SetText(""); nameInput:ClearFocus(); UI:RefreshBlacklistWindow() end end)

    local purgeBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate"); purgeBtn:SetSize(60, 22); purgeBtn:SetText("|cFFFFCC00Purge List|r"); if purgeBtn:GetFontString() then purgeBtn:GetFontString():SetTextColor(1, 0.3, 0.3) end
    purgeBtn:SetPoint("LEFT", addBtn, "RIGHT", 8, 0)
    purgeBtn:SetScript("OnClick", function() StaticPopupDialogs["GildeaOrdo_CONFIRM_PURGE_BL_1"] = { text = "Are you sure you want to clear the Blacklist?", button1 = "Yes", button2 = "Cancel", OnAccept = function() StaticPopupDialogs["GildeaOrdo_CONFIRM_PURGE_BL_2"] = { text = "WARNING: This will permanently delete ALL entries. Are you absolutely sure?", button1 = "PURGE ALL", button2 = "Cancel", OnAccept = function() if addon.ClearBlacklist then addon:ClearBlacklist() end end, timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3 }; StaticPopup_Show("GildeaOrdo_CONFIRM_PURGE_BL_2") end, timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3 }; StaticPopup_Show("GildeaOrdo_CONFIRM_PURGE_BL_1") end)

    local listPanel = CreateFrame("Frame", nil, f)
    listPanel:SetPoint("TOPLEFT", 16, -85); listPanel:SetPoint("BOTTOMRIGHT", -16, 120); listPanel:SetBackdrop(UI.PANEL_BACKDROP); listPanel:SetBackdropColor(0, 0, 0, 0.6)

    local scroll = CreateFrame("ScrollFrame", "GildeaOrdoBLScroll", listPanel, "FauxScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 4, -4); scroll:SetPoint("BOTTOMRIGHT", -26, 4)
    scroll:SetScript("OnVerticalScroll", function(self, offset) FauxScrollFrame_OnVerticalScroll(self, offset, BL_ROW_HEIGHT, function() UI:RefreshBlacklistWindow() end) end)

    for i = 1, MAX_BL_ROWS do
        local rowY = -((i - 1) * BL_ROW_HEIGHT) - 1
        local ii = i
        local row = listPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); row:SetPoint("TOPLEFT", scroll, "TOPLEFT", 6, rowY); row:SetPoint("RIGHT", scroll, "RIGHT", -4, 0); row:SetHeight(BL_ROW_HEIGHT); row:SetJustifyH("LEFT")
        local hit = CreateFrame("Button", nil, listPanel); hit:SetPoint("TOPLEFT", row, "TOPLEFT", -2, 0); hit:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", 2, 0)
        local hl = hit:CreateTexture(nil, "HIGHLIGHT"); hl:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight"); hl:SetBlendMode("ADD"); hl:SetAllPoints(hit)
        hit:SetScript("OnClick", function()
            local filter = f.nameInput and f.nameInput:GetText() or ""
            local dataNow = addon:GetBlacklist(filter) or {}
            local offset = (scroll and FauxScrollFrame_GetOffset(scroll)) or 0
            local item = dataNow[ii + offset]
            if item then selectedBlacklistName = item; UI:ShowBlacklistDetail(selectedBlacklistName); UI:RefreshBlacklistWindow() end
        end)
        blRows[i] = { label = row, hit = hit }
    end

    local arLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormal"); arLabel:SetPoint("BOTTOMLEFT", 24, 100); arLabel:SetText("|cFFFFCC00Autoresponse (sent to blacklisted players on trigger)|r"); arLabel:SetTextColor(1, 0.8, 0)
    local arBg = CreateFrame("Frame", nil, f); arBg:SetPoint("TOPLEFT", arLabel, "BOTTOMLEFT", -6, -2); arBg:SetPoint("BOTTOMRIGHT", -18, 34); arBg:SetBackdrop(UI.PANEL_BACKDROP); arBg:SetBackdropColor(0, 0, 0, 0.7); arBg:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    local arEdit = CreateFrame("EditBox", "GildeaOrdoBLReplyEdit", arBg); arEdit:SetFontObject("ChatFontSmall"); arEdit:SetAutoFocus(false); arEdit:SetMultiLine(true); arEdit:SetMaxLetters(200); arEdit:SetPoint("TOPLEFT", 6, -4); arEdit:SetPoint("BOTTOMRIGHT", -6, 4); arEdit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    
    local saveReplyBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate"); saveReplyBtn:SetSize(70, 22); saveReplyBtn:SetText("|cFFFFCC00Save|r"); if saveReplyBtn:GetFontString() then saveReplyBtn:GetFontString():SetTextColor(1, 0.8, 0) end; saveReplyBtn:SetPoint("BOTTOMRIGHT", -18, 8)
    saveReplyBtn:SetScript("OnClick", function() addon:SetBlacklistReply(arEdit:GetText() or ""); print("|cFFFFCC00GildeaOrdo|r: Blacklist autoresponse saved.") end)

    f.arEdit = arEdit; f.scroll = scroll; f.nameInput = nameInput
    _G["GildeaOrdoBlacklistFrame"] = f; table.insert(UISpecialFrames, "GildeaOrdoBlacklistFrame")
    f:HookScript("OnShow", function() positionBlacklistWindow(f); UI:RefreshBlacklistWindow() end)
    f:HookScript("OnHide", function() if blacklistDetailFrame then blacklistDetailFrame:Hide() end; selectedBlacklistName = nil end)
    blacklistFrame = f
    return f
end

function UI:RefreshBlacklistWindow()
    local f = blacklistFrame
    if not f or not f:IsShown() then return end
    if f.arEdit and not f.arEdit:HasFocus() then f.arEdit:SetText(addon:GetBlacklistReply() or "") end
    local filterText = f.nameInput and f.nameInput:GetText() or ""
    local data = addon:GetBlacklist(filterText) or {}

    if selectedBlacklistName then
        local stillThere = false
        for _, n in ipairs(data) do if n == selectedBlacklistName then stillThere = true; break end end
        if not stillThere then selectedBlacklistName = nil; if blacklistDetailFrame then blacklistDetailFrame:Hide() end end
    end

    local scrollH = (f.scroll and f.scroll:GetHeight()) or 150
    local visible = math.min(MAX_BL_ROWS, math.max(1, math.floor((scrollH + 2) / BL_ROW_HEIGHT)))
    FauxScrollFrame_Update(f.scroll, #data, visible, BL_ROW_HEIGHT)
    local offset = FauxScrollFrame_GetOffset(f.scroll)

    for i = 1, MAX_BL_ROWS do
        local row = blRows[i]
        if not row then break end
        if i > visible then row.label:Hide(); if row.hit then row.hit:Hide() end else
            local item = data[i + offset]
            if not item then row.label:SetText(""); row.label:Hide(); if row.hit then row.hit:Hide() end else
                local display = item:sub(1,1):upper() .. item:sub(2)
                row.label:SetText(selectedBlacklistName == item and "|cffffcc00> " .. display .. "|r" or "|cffffffff" .. display .. "|r")
                row.label:Show(); if row.hit then row.hit:Show() end
            end
        end
    end
end

function UI:ShowBlacklistWindow() local f = buildBlacklistWindow(); if f then positionBlacklistWindow(f); f:Show(); if f.Raise then f:Raise() end; UI:RefreshBlacklistWindow() end end
function UI:ToggleBlacklistWindow() local f = buildBlacklistWindow(); if f then if f:IsShown() then f:Hide() else UI:ShowBlacklistWindow() end end end

local function buildBlacklistDetail()
    if blacklistDetailFrame then return blacklistDetailFrame end
    local f = CreateFrame("Frame", "GildeaOrdoBlacklistDetailFrame", UIParent)
    f:SetSize(390, 165); f:SetBackdrop(UI.BACKDROP); f:SetBackdropColor(0, 0, 0, 1); f:SetMovable(true); f:EnableMouse(true); f:SetClampedToScreen(true); f:SetFrameStrata("HIGH")
    f:RegisterForDrag("LeftButton"); f:SetScript("OnDragStart", f.StartMoving); f:SetScript("OnDragStop", f.StopMovingOrSizing); f:Hide()
    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton"); close:SetPoint("TOPRIGHT", 2, 2)

    f.nameText = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge"); f.nameText:SetPoint("TOPLEFT", 16, -18); f.nameText:SetText("")
    f.removeBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate"); f.removeBtn:SetSize(80, 22); f.removeBtn:SetText("|cFFFFCC00Remove|r"); if f.removeBtn:GetFontString() then f.removeBtn:GetFontString():SetTextColor(1, 0.8, 0) end
    f.removeBtn:SetPoint("TOPRIGHT", -44, -18)
    f.removeBtn:SetScript("OnClick", function() if selectedBlacklistName then addon:RemoveFromBlacklist(selectedBlacklistName); selectedBlacklistName = nil; UI:RefreshBlacklistWindow() end; f:Hide() end)

    f.noteLabel = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); f.noteLabel:SetPoint("TOPLEFT", 16, -46); f.noteLabel:SetText("|cFFFFCC00Local Note:|r")
    local noteBg = CreateFrame("Frame", nil, f); noteBg:SetPoint("TOPLEFT", f.noteLabel, "BOTTOMLEFT", 0, -2); noteBg:SetPoint("RIGHT", f.removeBtn, "RIGHT", 0, 0); noteBg:SetHeight(75); noteBg:SetBackdrop(UI.PANEL_BACKDROP); noteBg:SetBackdropColor(0, 0, 0, 0.7); noteBg:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)

    f.noteEdit = CreateFrame("EditBox", "GildeaOrdoBLDetailNote", noteBg); f.noteEdit:SetFontObject("ChatFontSmall"); f.noteEdit:SetAutoFocus(false); f.noteEdit:SetMultiLine(true); f.noteEdit:SetMaxLetters(200); f.noteEdit:SetPoint("TOPLEFT", 6, -2); f.noteEdit:SetPoint("BOTTOMRIGHT", -4, 2); f.noteEdit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end); f.noteEdit:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    f.noteEdit:SetScript("OnEditFocusLost", function(self) if selectedBlacklistName then addon:SetBlacklistNote(selectedBlacklistName, self:GetText() or "") end end)

    local saveNoteBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate"); saveNoteBtn:SetSize(60, 22); saveNoteBtn:SetText("|cFFFFCC00Save|r"); if saveNoteBtn:GetFontString() then saveNoteBtn:GetFontString():SetTextColor(1, 0.8, 0) end
    saveNoteBtn:SetPoint("TOPRIGHT", noteBg, "BOTTOMRIGHT", 0, -1)
    saveNoteBtn:SetScript("OnClick", function() if selectedBlacklistName and f.noteEdit then addon:SetBlacklistNote(selectedBlacklistName, f.noteEdit:GetText() or ""); f.noteEdit:ClearFocus() end end)

    f:HookScript("OnShow", function()
        if blacklistFrame and blacklistFrame:IsShown() then f:ClearAllPoints(); f:SetPoint("TOPLEFT", blacklistFrame, "BOTTOMLEFT", 0, -4); f:SetWidth(blacklistFrame:GetWidth() or 390)
        else f:ClearAllPoints(); f:SetPoint("TOPLEFT", UIParent, "CENTER", -60, -80) end
    end)
    blacklistDetailFrame = f
    return f
end

function UI:ShowBlacklistDetail(name)
    if not name or name == "" then return end
    local f = buildBlacklistDetail()
    if not f then return end
    selectedBlacklistName = name; f.nameText:SetText("|cffffffff" .. (name:sub(1,1):upper() .. name:sub(2)) .. "|r")
    if f.noteEdit and not f.noteEdit:HasFocus() then f.noteEdit:SetText(addon:GetBlacklistNote(name) or "") end
    if blacklistFrame and blacklistFrame:IsShown() then f:ClearAllPoints(); f:SetPoint("TOPLEFT", blacklistFrame, "BOTTOMLEFT", 0, -4); f:SetWidth(blacklistFrame:GetWidth() or 390) else f:ClearAllPoints(); f:SetPoint("TOPLEFT", UIParent, "CENTER", -60, -80) end
    f:Show(); if f.Raise then f:Raise() end
end

function UI:RefreshBlacklistDetail()
    local f = blacklistDetailFrame
    if not f or not f:IsShown() or not selectedBlacklistName then return end
    f.nameText:SetText("|cffffffff" .. (selectedBlacklistName:sub(1,1):upper() .. selectedBlacklistName:sub(2)) .. "|r")
    if f.noteEdit and not f.noteEdit:HasFocus() then f.noteEdit:SetText(addon:GetBlacklistNote(selectedBlacklistName) or "") end
end

function UI:HideBlacklistDetail() if blacklistDetailFrame then blacklistDetailFrame:Hide() end; selectedBlacklistName = nil end