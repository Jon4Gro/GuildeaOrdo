-- GuildeaOrdo Alts UI Module
local addon = GuildeaOrdo
local UI    = addon.UI

function UI.BuildAlts(f)
    f.altInputAlt  = CreateFrame("EditBox", "GuildeaOrdoAltInput",  f, "InputBoxTemplate")
    f.altInputMain = CreateFrame("EditBox", "GuildeaOrdoMainInput", f, "InputBoxTemplate")
    f.altInputAlt:SetSize(120, 20); f.altInputMain:SetSize(120, 20)
    f.altInputAlt:SetPoint("BOTTOMLEFT",  24, 22); f.altInputMain:SetPoint("LEFT", f.altInputAlt, "RIGHT", 12, 0)
    f.altInputAlt:SetAutoFocus(false); f.altInputMain:SetAutoFocus(false)
    f.altInputAlt:SetScript("OnEscapePressed",  f.altInputAlt.ClearFocus); f.altInputMain:SetScript("OnEscapePressed", f.altInputMain.ClearFocus)

    f.altInputAltLabel = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.altInputAltLabel:SetPoint("BOTTOMLEFT", f.altInputAlt, "TOPLEFT", 0, 2); f.altInputAltLabel:SetText("Alt name")
    f.altInputMainLabel = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.altInputMainLabel:SetPoint("BOTTOMLEFT", f.altInputMain, "TOPLEFT", 0, 2); f.altInputMainLabel:SetText("Main name")

    f.altBtnSet = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    f.altBtnSet:SetSize(60, 22); f.altBtnSet:SetText("|cFFFFCC00Set|r")
    if f.altBtnSet:GetFontString() then f.altBtnSet:GetFontString():SetTextColor(1, 0.8, 0) end
    f.altBtnSet:SetPoint("LEFT", f.altInputMain, "RIGHT", 8, 0)
    f.altBtnSet:SetScript("OnClick", function()
        local a, m = f.altInputAlt:GetText(), f.altInputMain:GetText()
        if a and a ~= "" and m and m ~= "" then
            local ok, msg = addon:SetAlt(a, m)
            print("|cFFFFCC00GuildeaOrdo|r: " .. tostring(msg))
            f.altInputAlt:SetText(""); f.altInputMain:SetText(""); UI:Refresh()
        end
    end)

    f.altBtnUnset = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    f.altBtnUnset:SetSize(60, 22); f.altBtnUnset:SetText("|cFFFFCC00Unset|r")
    if f.altBtnUnset:GetFontString() then f.altBtnUnset:GetFontString():SetTextColor(1, 0.8, 0) end
    f.altBtnUnset:SetPoint("LEFT", f.altBtnSet, "RIGHT", 4, 0)
    f.altBtnUnset:SetScript("OnClick", function()
        local a = f.altInputAlt:GetText()
        if a and a ~= "" then
            local ok, msg = addon:SetAlt(a, nil)
            print("|cFFFFCC00GuildeaOrdo|r: " .. tostring(msg))
            f.altInputAlt:SetText(""); UI:Refresh()
        end
    end)
end

function UI.CollectAltsRows()
    local guild = addon:GetCurrentGuild()
    local rows = {}
    if not guild then return rows end
    for alt, main in pairs(guild.alts) do table.insert(rows, { alt = alt, main = main }) end
    table.sort(rows, function(a, b) if a.main == b.main then return a.alt < b.alt end; return a.main < b.main end)
    return rows
end
