-- GuildeaOrdo Settings UI Module
local addon = GuildeaOrdo
local UI    = addon.UI

function UI.BuildSettings(f)

    f.slashCmdLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    f.slashCmdLabel:SetPoint("TOPLEFT", 24, -80)
    f.slashCmdLabel:SetText("|cFFFFCC00Slash Commands|r")

    f.slashCmdText = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.slashCmdText:SetPoint("TOPLEFT", f.slashCmdLabel, "BOTTOMLEFT", 0, -8)
    f.slashCmdText:SetJustifyH("LEFT")
    f.slashCmdText:SetText("|cFFFFFF00/go|r or |cFFFFFF00/GuildeaOrdo|r - Toggle main window\n" ..
    "|cFFFFFF00/go bladd <name>|r - Add player to blacklist (Auto Guild/Group Invite)\n" ..
    "|cFFFFFF00/go bl|r or |cFFFFFF00/go blacklist|r - Show current blacklist in chat\n" ..
    "|cFFFFFF00/go inv <name>|r - Safely invite a player (checks blacklist first)\n" ..
    "|cFFFFFF00/go invl|r - Safely invite the last player who whispered you")

    f.batchSizeLabel = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    f.batchSizeLabel:SetPoint("TOPRIGHT", -84, -230); f.batchSizeLabel:SetText("|cFFFFCC00Mass Action Batch Size (per sec):|r"); f.batchSizeLabel:SetTextColor(1, 0.8, 0)

    f.batchSizeInput = CreateFrame("EditBox", "GuildeaOrdoBatchSize", f, "InputBoxTemplate")
    f.batchSizeInput:SetSize(26, 20); f.batchSizeInput:SetPoint("LEFT", f.batchSizeLabel, "RIGHT", 13, 0); f.batchSizeInput:SetAutoFocus(false); f.batchSizeInput:SetNumeric(true)
    f.batchSizeInput:SetScript("OnTextChanged", function(self) if GuildeaOrdoDB then GuildeaOrdoDB.batchSize = tonumber(self:GetText()) or 2 end end)

    f.openWithGuildCB = CreateFrame("CheckButton", "GuildeaOrdoOpenWithGuildCB", f, "OptionsBaseCheckButtonTemplate")
    f.openWithGuildCB:SetSize(20, 20); f.openWithGuildCB:SetPoint("TOPLEFT", f.batchSizeLabel, "BOTTOMLEFT", 0, -12)
    f.openWithGuildCB:SetScript("OnClick", function(self) if GuildeaOrdoCharDB then GuildeaOrdoCharDB.openWithGuild = self:GetChecked() and true or false end end)
    f.openWithGuildLabel = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.openWithGuildLabel:SetPoint("LEFT", f.openWithGuildCB, "RIGHT", 4, 0); f.openWithGuildLabel:SetText("Open GuildeaOrdo with Guild Frame")

    f.closeWithGuildCB = CreateFrame("CheckButton", "GuildeaOrdoCloseWithGuildCB", f, "OptionsBaseCheckButtonTemplate")
    f.closeWithGuildCB:SetSize(20, 20); f.closeWithGuildCB:SetPoint("TOPLEFT", f.openWithGuildCB, "BOTTOMLEFT", 0, -6)
    f.closeWithGuildCB:SetScript("OnClick", function(self) if GuildeaOrdoCharDB then GuildeaOrdoCharDB.closeWithGuild = self:GetChecked() and true or false end end)
    f.closeWithGuildLabel = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.closeWithGuildLabel:SetPoint("LEFT", f.closeWithGuildCB, "RIGHT", 4, 0); f.closeWithGuildLabel:SetText("Close GuildeaOrdo with Guild Frame")

    f.bracketInfoLabel = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.bracketInfoLabel:SetPoint("TOPLEFT", f.closeWithGuildCB, "BOTTOMLEFT", 0, -12)
    f.bracketInfoLabel:SetText("Officer Note Date Brackets:")

    local function mkBrk(name, w, anchor, x, dbKey)
    local eb = CreateFrame("EditBox", name, f, "InputBoxTemplate")
    eb:SetSize(w, 20); eb:SetPoint("LEFT", anchor, "RIGHT", x, 0); eb:SetAutoFocus(false)
    eb:SetScript("OnTextChanged", function(self) if GuildeaOrdoDB then GuildeaOrdoDB[dbKey] = self:GetText() end end)
    return eb
    end

    f.bLeftLbl = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); f.bLeftLbl:SetPoint("TOPLEFT", f.bracketInfoLabel, "BOTTOMLEFT", 0, -8); f.bLeftLbl:SetText("Left:")
    f.bLeft = mkBrk("GO_BLeft", 20, f.bLeftLbl, 6, "bracketLeft")
    f.bRightLbl = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); f.bRightLbl:SetPoint("LEFT", f.bLeft, "RIGHT", 10, 0); f.bRightLbl:SetText("Right:")
    f.bRight = mkBrk("GO_BRight", 20, f.bRightLbl, 6, "bracketRight")

    f.showMinimapCB = CreateFrame("CheckButton", "GuildeaOrdoShowMinimapCB", f, "OptionsBaseCheckButtonTemplate")
    f.showMinimapCB:SetSize(20, 20); f.showMinimapCB:SetPoint("TOPRIGHT", -120, -90)
    f.showMinimapCB:SetScript("OnClick", function(self) if GuildeaOrdoDB then GuildeaOrdoDB.showMinimapButton = self:GetChecked() and true or false; if addon.UpdateMinimapButton then addon:UpdateMinimapButton() end end end)
    f.showMinimapLabel = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.showMinimapLabel:SetPoint("RIGHT", f.showMinimapCB, "LEFT", -4, 0); f.showMinimapLabel:SetText("Show Minimap Button")

    f.minimapCtrlLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    f.minimapCtrlLabel:SetPoint("TOPRIGHT", f.showMinimapCB, -10, -24); f.minimapCtrlLabel:SetText("|cFFFFCC00Minimap Button Position|r"); f.minimapCtrlLabel:SetTextColor(1, 0.8, 0)

    f.minimapRotLabel = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.minimapRotLabel:SetPoint("TOPLEFT", f.minimapCtrlLabel, "BOTTOMLEFT", 0, -8); f.minimapRotLabel:SetText("|cFFFFCC00Rotation|r"); f.minimapRotLabel:SetTextColor(1, 0.8, 0)
    f.minimapRotSlider = CreateFrame("Slider", nil, f)
    f.minimapRotSlider:SetOrientation("HORIZONTAL"); f.minimapRotSlider:SetSize(150, 16); f.minimapRotSlider:SetPoint("LEFT", f.minimapRotLabel, "RIGHT", 6, 0); f.minimapRotSlider:SetMinMaxValues(0, 360); f.minimapRotSlider:SetValueStep(5)
    f.minimapRotSlider:SetBackdrop({ bgFile = "Interface\\Buttons\\UI-SliderBar-Background", edgeFile = "Interface\\Buttons\\UI-SliderBar-Border", tile = true, tileSize = 8, edgeSize = 8, insets = { left = 3, right = 3, top = 6, bottom = 6 } })
    f.minimapRotSlider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal"); if f.minimapRotSlider:GetThumbTexture() then f.minimapRotSlider:GetThumbTexture():SetSize(14, 20) end
    f.minimapRotLow = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall"); f.minimapRotLow:SetPoint("TOPLEFT", f.minimapRotSlider, "BOTTOMLEFT", 2, 0); f.minimapRotLow:SetText("0")
    f.minimapRotHigh = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall"); f.minimapRotHigh:SetPoint("TOPRIGHT", f.minimapRotSlider, "BOTTOMRIGHT", -2, 0); f.minimapRotHigh:SetText("360")
    f.minimapRotVal = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); f.minimapRotVal:SetPoint("LEFT", f.minimapRotSlider, "RIGHT", 6, 0)
    f.minimapRotSlider:SetScript("OnValueChanged", function(self, val) local v = math.floor(val / 5 + 0.5) * 5; v = math.max(0, math.min(360, v)); if GuildeaOrdoDB then GuildeaOrdoDB.minimapRotation = v end; if f.minimapRotVal then f.minimapRotVal:SetText(tostring(v)) end; if addon.UpdateMinimapPos then addon.UpdateMinimapPos() end end)

    f.minimapDistLabel = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.minimapDistLabel:SetPoint("TOPLEFT", f.minimapRotLabel, "BOTTOMLEFT", 0, -16); f.minimapDistLabel:SetText("|cFFFFCC00Distance|r"); f.minimapDistLabel:SetTextColor(1, 0.8, 0)
    f.minimapDistSlider = CreateFrame("Slider", nil, f)
    f.minimapDistSlider:SetOrientation("HORIZONTAL"); f.minimapDistSlider:SetSize(150, 16); f.minimapDistSlider:SetPoint("LEFT", f.minimapDistLabel, "RIGHT", 6, 0); f.minimapDistSlider:SetMinMaxValues(20, 240); f.minimapDistSlider:SetValueStep(2)
    f.minimapDistSlider:SetBackdrop({ bgFile = "Interface\\Buttons\\UI-SliderBar-Background", edgeFile = "Interface\\Buttons\\UI-SliderBar-Border", tile = true, tileSize = 8, edgeSize = 8, insets = { left = 3, right = 3, top = 6, bottom = 6 } })
    f.minimapDistSlider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal"); if f.minimapDistSlider:GetThumbTexture() then f.minimapDistSlider:GetThumbTexture():SetSize(14, 20) end
    f.minimapDistLow = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall"); f.minimapDistLow:SetPoint("TOPLEFT", f.minimapDistSlider, "BOTTOMLEFT", 2, 0); f.minimapDistLow:SetText("20")
    f.minimapDistHigh = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall"); f.minimapDistHigh:SetPoint("TOPRIGHT", f.minimapDistSlider, "BOTTOMRIGHT", -2, 0); f.minimapDistHigh:SetText("240")
    f.minimapDistVal = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); f.minimapDistVal:SetPoint("LEFT", f.minimapDistSlider, "RIGHT", 6, 0)
    f.minimapDistSlider:SetScript("OnValueChanged", function(self, val) local v = math.floor(val / 2 + 0.5) * 2; v = math.max(20, math.min(240, v)); if GuildeaOrdoDB then GuildeaOrdoDB.minimapDistance = v end; if f.minimapDistVal then f.minimapDistVal:SetText(tostring(v)) end; if addon.UpdateMinimapPos then addon.UpdateMinimapPos() end end)

    f.autoInvLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormal"); f.autoInvLabel:SetPoint("BOTTOMLEFT", 24, 120); f.autoInvLabel:SetText("|cFFFFCC00Auto Guild  Invite|r"); f.autoInvLabel:SetTextColor(1, 0.8, 0)
    f.autoInvCB = CreateFrame("CheckButton", "GuildeaOrdoAutoInvCB", f, "OptionsBaseCheckButtonTemplate")
    f.autoInvCB:SetSize(24, 24); f.autoInvCB:SetPoint("TOPLEFT", f.autoInvLabel, "BOTTOMLEFT", 0, -20)
    f.autoInvCB:SetScript("OnClick", function(self) GuildeaOrdoCharDB.autoInvite.enabled = self:GetChecked(); UI:Refresh() end)
    f.autoInvCBLabel = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); f.autoInvCBLabel:SetPoint("LEFT", f.autoInvCB, "RIGHT", 2, 1); f.autoInvCBLabel:SetText("Enable")

    local function mkAIEB(name, labelTxt, width, anchorFrame, relPoint, x, y, dbKey)
        local bg = CreateFrame("Frame", nil, f); bg:SetPoint("TOPLEFT", anchorFrame, relPoint, x, y); bg:SetSize(width, 22); bg:SetBackdrop(UI.PANEL_BACKDROP); bg:SetBackdropColor(0, 0, 0, 0.7); bg:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
        local lbl = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); lbl:SetPoint("BOTTOMLEFT", bg, "TOPLEFT", 0, 2); lbl:SetText(labelTxt)
        local eb = CreateFrame("EditBox", name, bg); eb:SetFontObject("ChatFontSmall"); eb:SetAutoFocus(false); eb:SetPoint("TOPLEFT", 6, -3); eb:SetPoint("BOTTOMRIGHT", -4, 3); eb:SetScript("OnEscapePressed", function(self) self:ClearFocus() end); eb:SetScript("OnTextChanged", function(self) if dbKey and GuildeaOrdoDB and GuildeaOrdoCharDB.autoInvite then GuildeaOrdoCharDB.autoInvite[dbKey] = self:GetText() end end)
        return bg, eb, lbl
    end
    f.aiPhraseBg, f.aiPhrase, f.aiPhraseLbl = mkAIEB("GM_AI_Phrase", " Trigger Words (can be multiple seperate with - ):", 380, f.autoInvCB, "BOTTOM", -13, -32, "phrase")
    f.aiOnBg, f.aiOn, f.aiOnLbl             = mkAIEB("GM_AI_On", " Auto-Reply:", 300, f.autoInvCBLabel, "TOPRIGHT", 14, -5, "replyOn")
    f.aiOffBg, f.aiOff, f.aiOffLbl          = mkAIEB("GM_AI_Off", " Reply if OFF:", 300, f.aiOnBg, "TOPRIGHT", 10, 0, "replyOff")
    f.aiMinLvlBg, f.aiMinLvl, f.aiMinLvlLbl = mkAIEB("GM_AI_MinLvl", " Min Lvl:", 50, f.aiPhrase, "RIGHT", 10, 11, "minLvl"); f.aiMinLvl:SetNumeric(true)
    f.aiReplyLowBg, f.aiReplyLow, f.aiReplyLowLbl = mkAIEB("GM_AI_ReplyLow", " Reply if too Low:", 240, f.aiMinLvlBg, "RIGHT", 10, 11, "replyLow")

    f.autoInvBg = CreateFrame("Frame", nil, f)
    f.autoInvBg:SetBackdrop({ bgFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1, insets = { left = 0, right = 0, top = 0, bottom = 0 } }); f.autoInvBg:SetBackdropColor(0.05, 0.05, 0.05, 0.6); f.autoInvBg:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8)
    f.autoInvBg:SetPoint("TOPLEFT", f.autoInvLabel, "TOPLEFT", -6, -18); f.autoInvBg:SetPoint("BOTTOMRIGHT", f.aiReplyLow, "RIGHT", 10, -18); f.autoInvBg:SetFrameLevel(math.max(0, f.autoInvCB:GetFrameLevel() - 1))

    f.groupInviteLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormal"); f.groupInviteLabel:SetPoint("BOTTOMLEFT", f.autoInvCB, "BOTTOMLEFT", 0, 170); f.groupInviteLabel:SetText("|cFFFFCC00Auto Group Invite|r"); f.groupInviteLabel:SetTextColor(1, 0.8, 0)
    f.groupInviteCheck = CreateFrame("CheckButton", "GuildeaOrdoGroupInviteCheck", f, "InterfaceOptionsCheckButtonTemplate"); f.groupInviteCheck:SetPoint("TOPLEFT", f.groupInviteLabel, "BOTTOMLEFT", 0, -13); GuildeaOrdoGroupInviteCheckText:SetText("Auto Group On/Off: ")
    f.groupInviteEditBoxLabel = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); f.groupInviteEditBoxLabel:SetPoint("BOTTOMLEFT", f.groupInviteCheck , "RIGHT", -19, -34); f.groupInviteEditBoxLabel:SetText("Trigger Words (seperate with -): ")
    f.groupInviteEditBox = CreateFrame("EditBox", "GuildeaOrdoGroupInviteEditBox", f, "InputBoxTemplate"); f.groupInviteEditBox:SetSize(490, 20); f.groupInviteEditBox:SetPoint("BOTTOMLEFT",  f.groupInviteCheck , "RIGHT", -18, -60); f.groupInviteEditBox:SetAutoFocus(false); f.groupInviteEditBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end); f.groupInviteEditBox:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    f.groupInviteEditBox:SetScript("OnTextChanged", function(self) if GuildeaOrdoDB and GuildeaOrdoCharDB.autoInvite then GuildeaOrdoCharDB.autoInvite.groupinv = self:GetText() or "" end end)

    f.groupInviteMinutes = CreateFrame("EditBox", "GuildeaOrdoGroupInviteMinutes", f, "InputBoxTemplate"); f.groupInviteMinutes:SetSize(28, 20); f.groupInviteMinutes:SetPoint("LEFT", GuildeaOrdoGroupInviteCheckText, "RIGHT", 8, 0); f.groupInviteMinutes:SetNumeric(true); f.groupInviteMinutes:SetAutoFocus(false); f.groupInviteMinutes:SetText("15")
    f.groupInviteMinutes:SetScript("OnTextChanged", function(self) if GuildeaOrdoDB and GuildeaOrdoCharDB.autoInvite then local v = tonumber(self:GetText()); GuildeaOrdoCharDB.autoInvite.groupMinutes = (v ~= nil) and v or 15 end end); f.groupInviteMinutes:SetScript("OnEscapePressed", function(self) self:ClearFocus() end); f.groupInviteMinutes:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    
    -- Removed Permanent Checkbox. Replaced with automatic setting reading the Minutes = 0.
    f.groupInviteCheck:SetScript("OnClick", function(self)
        local checked = self:GetChecked()
        if checked then
            local mins = tonumber(f.groupInviteMinutes and f.groupInviteMinutes:GetText()) or 15
            addon.groupInvitePermanent = (mins == 0)
            addon:StartGroupInvite(mins)
        else
            addon:StopGroupInvite()
        end
    end)

    f.groupInviteBg = CreateFrame("Frame", nil, f); f.groupInviteBg:SetBackdrop({ bgFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1, insets = { left = 0, right = 0, top = 0, bottom = 0 } })
    f.groupInviteMinLabel = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); f.groupInviteMinLabel:SetPoint("LEFT", f.groupInviteMinutes, "RIGHT", 4, 0); f.groupInviteMinLabel:SetText("Minutes (0 = Infinite)")
    f.groupInviteBg:SetBackdropColor(0.05, 0.05, 0.05, 0.6); f.groupInviteBg:SetBackdropBorderColor(0.3, 0.3, 0.3, 0.8); f.groupInviteBg:SetPoint("TOPLEFT", f.groupInviteCheck, "TOPLEFT", -6, 5); f.groupInviteBg:SetPoint("BOTTOMRIGHT", f.groupInviteEditBox, "BOTTOMRIGHT", 6, -13); f.groupInviteBg:SetFrameLevel(math.max(0, f.groupInviteCheck:GetFrameLevel() - 1))

    f:HookScript("OnShow", function()
        if f.groupInviteCheck then f.groupInviteCheck:SetChecked(addon.groupInviteActive) end
        if GuildeaOrdoDB and GuildeaOrdoCharDB.autoInvite then
            if f.groupInviteEditBox then f.groupInviteEditBox:SetText(GuildeaOrdoCharDB.autoInvite.groupinv or "") end
            if f.groupInviteMinutes then f.groupInviteMinutes:SetText(tostring(GuildeaOrdoCharDB.autoInvite.groupMinutes or 15)) end
        end
    end)

    f.shareBlacklistBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    f.shareBlacklistBtn:SetSize(130, 24); f.shareBlacklistBtn:SetPoint("BOTTOMRIGHT", -18, 18); f.shareBlacklistBtn:SetText("|cFFFFCC00Share BL|r")
    if f.shareBlacklistBtn:GetFontString() then f.shareBlacklistBtn:GetFontString():SetTextColor(1, 0.8, 0) end
    f.shareBlacklistBtn:SetScript("OnClick", function() if addon.ShareBlacklist then addon:ShareBlacklist() end end)

    f.autoBanLeaveCB = CreateFrame("CheckButton", "GuildeaOrdoAutoBanLeaveCB", f, "OptionsBaseCheckButtonTemplate")
    f.autoBanLeaveCB:SetSize(20, 20); f.autoBanLeaveCB:SetPoint("BOTTOMRIGHT", -18, 46)
    f.autoBanLeaveCB:SetScript("OnClick", function(self) if GuildeaOrdoDB then GuildeaOrdoDB.autoBanOnLeave = self:GetChecked() and true or false end end)
    f.autoBanLeaveLabel = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); f.autoBanLeaveLabel:SetPoint("RIGHT", f.autoBanLeaveCB, "LEFT", -4, 0); f.autoBanLeaveLabel:SetText("Auto Ban on Leaving")

    f.blacklistBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    f.blacklistBtn:SetSize(130, 24); f.blacklistBtn:SetPoint("BOTTOMRIGHT", -18, 72); f.blacklistBtn:SetText("|cFFFFCC00Blacklist|r")
    if f.blacklistBtn:GetFontString() then f.blacklistBtn:GetFontString():SetTextColor(1, 0.8, 0) end
    f.blacklistBtn:SetScript("OnClick", function() UI:ToggleBlacklistWindow() end)
end
