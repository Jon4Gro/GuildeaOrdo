-- GuildeaOrdo Log UI Module
local addon = GuildeaOrdo
local UI    = addon.UI

function UI.BuildLog(f)
    -- Search Input
    f.logSearch = CreateFrame("EditBox", "GuildeaOrdoLogSearch", f, "InputBoxTemplate")
    f.logSearch:SetSize(220, 20)
    f.logSearch:SetPoint("TOPLEFT", f.tabLog, "BOTTOMLEFT", 8, -18)
    f.logSearch:SetAutoFocus(false)
    f.logSearch:SetScript("OnTextChanged", function(self) UI.logSearchText = self:GetText() or ""; UI:Refresh() end)
    f.logSearch:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    f.logSearch:SetScript("OnEnterPressed",  function(self) self:ClearFocus() end)
    
    f.logSearchLabel = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.logSearchLabel:SetPoint("BOTTOMLEFT", f.logSearch, "TOPLEFT", -4, 1)
    f.logSearchLabel:SetText("Search Filter")

    -- Filter Checkboxes Panel
    f.filterPanel = CreateFrame("Frame", nil, f)
    f.filterPanel:SetSize(150, 294)
    f.filterPanel:SetPoint("TOPRIGHT", -18, -130)
    f.filterPanel:SetBackdrop(UI.PANEL_BACKDROP)
    f.filterPanel:SetBackdropColor(0, 0, 0, 0.6)

    local fpTitle = f.filterPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fpTitle:SetPoint("TOP", 0, -8)
    fpTitle:SetText("|cFFFFCC00Display Changes|r")
    fpTitle:SetTextColor(1, 0.8, 0)

    f.filterChecks = {}
    local cbY = -30
    for _, key in ipairs(UI.TYPE_ORDER) do
        local cb = CreateFrame("CheckButton", "GuildeaOrdoFC_" .. key, f.filterPanel, "OptionsBaseCheckButtonTemplate")
        cb:SetSize(20, 20); cb:SetPoint("TOPLEFT", 10, cbY); cb:SetChecked(UI.typeFilters[key])
        local labelKey = key
        cb:SetScript("OnClick", function(self) UI.typeFilters[labelKey] = self:GetChecked() and true or false; UI:Refresh() end)
        local lbl = f.filterPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        lbl:SetPoint("LEFT", cb, "RIGHT", 4, 0)
        lbl:SetText(UI.colorize(key, UI.TYPE_LABEL[key] or key))
        f.filterChecks[key] = cb
        cbY = cbY - 22
    end

    local checkAll = CreateFrame("Button", nil, f.filterPanel, "UIPanelButtonTemplate")
    checkAll:SetSize(60, 20); checkAll:SetText("All"); checkAll:SetPoint("BOTTOMLEFT", 10, 10)
    checkAll:SetScript("OnClick", function()
        for _, k in ipairs(UI.TYPE_ORDER) do UI.typeFilters[k] = true end
        for _, cb in pairs(f.filterChecks) do cb:SetChecked(true) end
        UI:Refresh()
    end)
    local clearAll = CreateFrame("Button", nil, f.filterPanel, "UIPanelButtonTemplate")
    clearAll:SetSize(60, 20); clearAll:SetText("None"); clearAll:SetPoint("BOTTOMRIGHT", -10, 10)
    clearAll:SetScript("OnClick", function()
        for _, k in ipairs(UI.TYPE_ORDER) do UI.typeFilters[k] = false end
        for _, cb in pairs(f.filterChecks) do cb:SetChecked(false) end
        UI:Refresh()
    end)

    -- Numbered + Clear Log Bottom Controls
    f.numberedCB = CreateFrame("CheckButton", "GuildeaOrdoNumberedCB", f, "OptionsBaseCheckButtonTemplate")
    f.numberedCB:SetSize(20, 20); f.numberedCB:SetPoint("BOTTOMLEFT", 24, 22)
    f.numberedCB:SetChecked(UI.showLineNumbers)
    f.numberedCB:SetScript("OnClick", function(self) UI.showLineNumbers = self:GetChecked() and true or false; UI:Refresh() end)
    f.numberedLabel = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.numberedLabel:SetPoint("LEFT", f.numberedCB, "RIGHT", 2, 0)
    f.numberedLabel:SetText("Numbered Lines")

    f.clearLogBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    f.clearLogBtn:SetSize(150, 24); f.clearLogBtn:SetText("|cFFFFCC00Clear Log|r")
    if f.clearLogBtn:GetFontString() then f.clearLogBtn:GetFontString():SetTextColor(1, 0.8, 0) end
    f.clearLogBtn:SetPoint("BOTTOMRIGHT", -18, 18)
    f.clearLogBtn:SetScript("OnClick", function() addon:ClearLog(); UI:Refresh() end)
end

function UI.CollectLogRows()
    local guild = addon:GetCurrentGuild()
    local rows = {}
    if not guild then return rows, 0 end

    local needle = UI.lowerSafe(UI.logSearchText)
    local total = #guild.log
    for i = total, 1, -1 do
        local e = guild.log[i]
        if e and UI.typeFilters[e.type] then
            if needle ~= "" then
                local hay = UI.lowerSafe((e.who or "") .. " " .. (e.details or "") .. " " .. (UI.TYPE_LABEL[e.type] or e.type))
                if hay:find(needle, 1, true) then table.insert(rows, { entry = e, n = i }) end
            else
                table.insert(rows, { entry = e, n = i })
            end
        end
    end
    return rows, total
end
