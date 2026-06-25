-- GildeaOrdo Macros UI Module
local addon = GildeaOrdo
local UI    = addon.UI

function UI.BuildMacros(f)
    f.macroMsgLabel = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.macroMsgLabel:SetPoint("TOPLEFT", f.tabLog, "BOTTOMLEFT", 0, -6)
    f.macroMsgLabel:SetText("Message  |cff888888(saves account-wide, max ~255 chars)|r")

    f.macroMsgBg = CreateFrame("Frame", nil, f)
    f.macroMsgBg:SetPoint("TOPLEFT", f.macroMsgLabel, "BOTTOMLEFT", 0, -2); f.macroMsgBg:SetSize(760, 44)
    f.macroMsgBg:SetBackdrop(UI.PANEL_BACKDROP); f.macroMsgBg:SetBackdropColor(0, 0, 0, 0.7); f.macroMsgBg:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)

    f.macroMsg = CreateFrame("EditBox", "GildeaOrdoMacroMsg", f.macroMsgBg)
    f.macroMsg:SetFontObject("ChatFontSmall"); f.macroMsg:SetAutoFocus(false); f.macroMsg:SetMultiLine(true); f.macroMsg:SetMaxLetters(255)
    f.macroMsg:SetPoint("TOPLEFT", 6, -4); f.macroMsg:SetPoint("BOTTOMRIGHT", -6, 4)
    f.macroMsg:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

    f.macroChanLabel = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.macroChanLabel:SetPoint("TOPLEFT", f.macroMsgBg, "BOTTOMLEFT", 0, -6); f.macroChanLabel:SetText("Channel:")

    f.macroChanBtns = {}
    local prevChanBtn
    for _, opt in ipairs(UI.CHANNEL_OPTIONS) do
        local b = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        b:SetSize(#opt > 2 and 56 or 26, 20); b:SetText("|cFFFFCC00" .. opt .. "|r")
        if b:GetFontString() then b:GetFontString():SetTextColor(1, 0.8, 0) end
        if prevChanBtn then b:SetPoint("LEFT", prevChanBtn, "RIGHT", 2, 0) else b:SetPoint("LEFT", f.macroChanLabel, "RIGHT", 6, 0) end
        local choice = opt
        b:SetScript("OnClick", function() UI.macroSelectedChannel = choice; UI:Refresh() end)
        f.macroChanBtns[opt] = b
        prevChanBtn = b
    end

    f.macroSaveBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    f.macroSaveBtn:SetSize(80, 22); f.macroSaveBtn:SetText("|cFFFFCC00Save Macro|r")
    if f.macroSaveBtn:GetFontString() then f.macroSaveBtn:GetFontString():SetTextColor(1, 0.8, 0) end
    f.macroSaveBtn:SetPoint("TOPLEFT", f.macroChanLabel, "BOTTOMLEFT", 0, -28)
    f.macroSaveBtn:SetScript("OnClick", function()
        local text = f.macroMsg:GetText() or ""
        if text == "" then return end
        if addon.editingMacroIndex then
            StaticPopupDialogs["GildeaOrdo_CONFIRM_MACRO_OVERWRITE"] = { text = "Overwrite existing macro?", button1 = "Yes", button2 = "No", OnAccept = function() GildeaOrdoDB.macros[addon.editingMacroIndex] = { channel = UI.macroSelectedChannel, text = text }; addon.editingMacroIndex = nil; f.macroMsg:SetText(""); f.macroMsg:ClearFocus(); UI:Refresh() end, timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3 }
            StaticPopup_Show("GildeaOrdo_CONFIRM_MACRO_OVERWRITE")
        else
            local ok, msg = addon:AddMacro(UI.macroSelectedChannel, text)
            if ok then print("|cFFFFCC00GildeaOrdo|r: macro saved."); f.macroMsg:SetText(""); f.macroMsg:ClearFocus() else print("|cFFFFCC00GildeaOrdo|r: " .. tostring(msg)) end
            UI:Refresh()
        end
    end)

    f.macroSpamCB = CreateFrame("CheckButton", "GildeaOrdoMacroSpamCB", f, "OptionsBaseCheckButtonTemplate")
    f.macroSpamCB:SetSize(20, 20); f.macroSpamCB:SetPoint("BOTTOMLEFT", 18, 24)
    f.macroSpamCB:SetScript("OnClick", function(self)
        addon.spamActive = self:GetChecked()
        addon.spamInterval = tonumber(f.macroSpamInterval:GetText()) or 5
        addon.spamTotalLimit = tonumber(f.macroSpamTotal and f.macroSpamTotal:GetText()) or 0
        if GildeaOrdoDB then GildeaOrdoDB.spamTotalMinutes = addon.spamTotalLimit end
        addon.spamTotalElapsed = 0
        local hasActive = false
        if addon.spamMacros then for k, v in pairs(addon.spamMacros) do if v then hasActive = true; break end end end
            if addon.spamActive and not hasActive then
            print("|cFFFFCC00GildeaOrdo|r: Please 'Set' at least one macro first.")
            self:SetChecked(false)
            addon.spamActive = false
            addon.spamTotalElapsed = 0
                elseif addon.spamActive then
                print("|cFFFFCC00GildeaOrdo|r: Macro Spam Started.")
                else
                print("|cFFFFCC00GildeaOrdo|r: Macro Spam Ended.")
                end
                addon.spamTimer = 0
        end)

    f.macroSpamLabel = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.macroSpamLabel:SetPoint("LEFT", f.macroSpamCB, "RIGHT", 6, 1); f.macroSpamLabel:SetText("Spam selected Macro every:")

    f.macroSpamInterval = CreateFrame("EditBox", "GildeaOrdoMacroSpamInterval", f, "InputBoxTemplate")
    f.macroSpamInterval:SetSize(36, 24); f.macroSpamInterval:SetPoint("LEFT", f.macroSpamLabel, "RIGHT", 13, 0); f.macroSpamInterval:SetNumeric(true); f.macroSpamInterval:SetAutoFocus(false); f.macroSpamInterval:EnableMouse(true); f.macroSpamInterval:SetText("5")
    f.macroSpamInterval:SetScript("OnTextChanged", function(self) addon.spamInterval = tonumber(self:GetText()) or 5 end)
    f.macroSpamInterval:SetScript("OnEscapePressed", function(self) self:ClearFocus() end); f.macroSpamInterval:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    
    f.macroSpamMinLabel = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.macroSpamMinLabel:SetPoint("LEFT", f.macroSpamInterval, "RIGHT", 4, 0); f.macroSpamMinLabel:SetText("minutes")

    f.macroSpamTotalLabel = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.macroSpamTotalLabel:SetPoint("LEFT", f.macroSpamMinLabel, "RIGHT", 8, 0); f.macroSpamTotalLabel:SetText("for the next: ")
    f.macroSpamTotal = CreateFrame("EditBox", "GildeaOrdoMacroSpamTotal", f, "InputBoxTemplate")
    f.macroSpamTotal:SetSize(30, 24); f.macroSpamTotal:SetPoint("LEFT", f.macroSpamTotalLabel, "RIGHT", 4, 0); f.macroSpamTotal:SetNumeric(true); f.macroSpamTotal:SetAutoFocus(false); f.macroSpamTotal:SetText("0")
    f.macroSpamTotal:SetScript("OnTextChanged", function(self) addon.spamTotalLimit = tonumber(self:GetText()) or 0; if GildeaOrdoDB then GildeaOrdoDB.spamTotalMinutes = addon.spamTotalLimit end end)
    f.macroSpamTotal:SetScript("OnEscapePressed", function(self) self:ClearFocus() end); f.macroSpamTotal:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    f.macroSpamTotalMinLabel = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.macroSpamTotalMinLabel:SetPoint("LEFT", f.macroSpamTotal, "RIGHT", 2, 0); f.macroSpamTotalMinLabel:SetText("minutes ( 0 = Infinite)")

    if GildeaOrdoDB then
        local tval = GildeaOrdoDB.spamTotalMinutes or 0
        f.macroSpamTotal:SetText(tostring(tval)); addon.spamTotalLimit = tval
    end
end

function UI.CollectMacrosRows()
    local rows, list = {}, addon:GetMacros()
    for i, m in ipairs(list) do table.insert(rows, { index = i, channel = m.channel, text = m.text }) end
    return rows
end
