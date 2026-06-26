-- GuildeaOrdo Roster overlay
-- A richer replacement for Wrath's GuildMemberDetailFrame.
-- When a guild member is selected, we hide Blizzard's small detail frame
-- and pop our own panel that shows everything GuildeaOrdo tracks plus the
-- standard Public Note / Officer's Note / Remove / Invite operations.

GuildeaOrdo = GuildeaOrdo or {}
local addon = GuildeaOrdo

-- =========================================================
-- Constants
-- =========================================================
local PANEL_W, PANEL_H = 280, 350

local FRAME_BACKDROP = {
    bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 },
}

local INPUT_BACKDROP = {
    bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 8,
    insets = { left = 2, right = 2, top = 2, bottom = 2 },
}

local SECTION_BACKDROP = {
    bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 10,
    insets = { left = 3, right = 3, top = 3, bottom = 3 },
}

local CLASS_COLOR = {
    DEATHKNIGHT = "|cffc41f3b",
    DRUID       = "|cffff7d0a",
    HUNTER      = "|cffabd473",
    MAGE        = "|cff69ccf0",
    PALADIN     = "|cfff58cba",
    PRIEST      = "|cffffffff",
    ROGUE       = "|cfffff569",
    SHAMAN      = "|cff0070de",
    WARLOCK     = "|cff9482c9",
    WARRIOR     = "|cffc79c6e",
}

-- =========================================================
-- Helpers
-- =========================================================
local function fmtSince(epoch)
    if not epoch then return "?" end
    local d = time() - epoch
    if d < 60       then return "online" end
    if d < 3600     then return ("%d min ago"):format(math.floor(d / 60)) end
    if d < 86400    then return ("%d hrs ago"):format(math.floor(d / 3600)) end
    if d < 604800   then return ("%d days ago"):format(math.floor(d / 86400)) end
    if d < 2592000  then return ("%d wks ago"):format(math.floor(d / 604800)) end
    if d < 31536000 then return ("%d mos ago"):format(math.floor(d / 2592000)) end
    return ("%d yrs ago"):format(math.floor(d / 31536000))
end

local function findRosterIndex(name)
    if not name or name == "" then return nil end
    local n = GetNumGuildMembers() or 0
    for i = 1, n do
        local rname = GetGuildRosterInfo(i)
        if rname == name then return i end
    end
    return nil
end

local function getMemberInfo(name)
    local idx = findRosterIndex(name)
    if not idx then return nil end
    local n, rank, _, level, _, zone, note, officerNote, online, _, classFile
        = GetGuildRosterInfo(idx)
    return {
        index       = idx,
        name        = n,
        rank        = rank or "",
        level       = level or 0,
        zone        = zone or "",
        note        = note or "",
        officerNote = officerNote or "",
        online      = online and true or false,
        classFile   = classFile or "",
    }
end

-- =========================================================
-- Panel (single instance, lazy-built)
-- =========================================================
local panel
local currentName  -- name of member currently displayed

local function refreshPanel()
    if not panel or not panel:IsShown() or not currentName then return end

    local info = getMemberInfo(currentName)
    local rec  = addon:GetMemberRecord(currentName)
    local main = addon:GetMainOf(currentName)
    local alts = addon:GetAltsOf(currentName)

    if not info then
        -- Member no longer in roster - close
        panel:Hide()
        return
    end

    -- Header
    local classCol = CLASS_COLOR[info.classFile] or "|cffeeeeee"
    panel.nameText:SetText(classCol .. info.name .. "|r")
    panel.levelText:SetText(("Level %d"):format(info.level))
    panel.rankText:SetText(("|cffffcc00%s|r"):format(info.rank))

    -- Stats
    -- Stats
    local joinDisplay = "(not tracked)"

    -- 1. Mainly read from the Officer Note (looks for format: [Jun 09 2026])
    local parsedNoteDate = string.match(info.officerNote or "", "%[(%a%a%a %d%d %d%d%d%d)%]")

    if parsedNoteDate then
        joinDisplay = parsedNoteDate
        -- 2. Fallback to local save
        elseif rec and rec.joinDateExact and rec.joinDate then
            joinDisplay = rec.joinDate
        end
        panel.joinedText:SetText(("|cffffcc00Joined:|r %s"):format(joinDisplay))

    local seenStr = info.online and "Online" or fmtSince(rec and rec.lastOnline)
    panel.lastSeenText:SetText(("|cffffcc00Last seen:|r %s"):format(seenStr))
    panel.zoneText:SetText(("|cffffcc00Zone:|r %s"):format(
        info.zone ~= "" and info.zone or "?"))

    -- Notes
    local canPub = CanEditPublicNote and CanEditPublicNote()
    local canOff = CanEditOfficerNote and CanEditOfficerNote()

    -- IMPORTANT: only overwrite the EditBox text when the user is NOT typing in
    -- it. The panel runs a periodic refresh poller, and calling SetText on an
    -- EditBox that has focus will wipe whatever the user has typed so far.
    if not panel.noteEdit:HasFocus() then
        panel.noteEdit:SetText(info.note)
    end
    if canPub then
        panel.noteEdit:EnableMouse(true)
        panel.noteEdit:EnableKeyboard(true)
        panel.noteEdit:SetTextColor(1, 1, 1)
    else
        panel.noteEdit:EnableMouse(false)
        panel.noteEdit:EnableKeyboard(false)
        panel.noteEdit:SetTextColor(0.6, 0.6, 0.6)
    end

    if not panel.officerEdit:HasFocus() then
        panel.officerEdit:SetText(info.officerNote)
    end
    if canOff then
        panel.officerEdit:EnableMouse(true)
        panel.officerEdit:EnableKeyboard(true)
        panel.officerEdit:SetTextColor(1, 1, 1)
    else
        panel.officerEdit:EnableMouse(false)
        panel.officerEdit:EnableKeyboard(false)
        panel.officerEdit:SetTextColor(0.6, 0.6, 0.6)
    end

    -- Alts section
    if main then
        panel.altStatus:SetText(("|cffaaaaffAlt of:|r |cffffcc00%s|r"):format(main))
    elseif #alts > 0 then
        panel.altStatus:SetText(("|cffaaaaffMain. Alts:|r %s"):format(
            table.concat(alts, ", ")))
    else
        panel.altStatus:SetText("|cff888888No alt link recorded.|r")
    end

    -- Promote / Demote permission gating
    local canPromote = CanGuildPromote and CanGuildPromote()
    local canDemote  = CanGuildDemote  and CanGuildDemote()
    local isSelf     = (info.name == (UnitName("player")))
    if canPromote and not isSelf then panel.btnPromote:Enable() else panel.btnPromote:Disable() end
    if canDemote  and not isSelf then panel.btnDemote:Enable()  else panel.btnDemote:Disable()  end
end

local function buildPanel()
    if panel then return panel end

    local f = CreateFrame("Frame", "GuildeaOrdoDetailPanel", UIParent)
    f:SetSize(PANEL_W, PANEL_H)
    f:SetPoint("CENTER")  -- repositioned on show
    f:SetBackdrop(FRAME_BACKDROP)
    f:SetBackdropColor(0, 0, 0, 1)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:SetClampedToScreen(true)
    f:SetFrameStrata("HIGH")
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop",  f.StopMovingOrSizing)
    f:Hide()


    -- Close button
    local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -2, -2)

    -- ===== Header section (name / level / rank) =====
    f.nameText = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    f.nameText:SetPoint("TOP", 0, -16)

    f.levelText = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    f.levelText:SetPoint("TOPLEFT", 26 , -32)

    f.rankText = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    f.rankText:SetPoint("TOPRIGHT", -26, -32)

    -- ===== Stats section =====
    f.statsPanel = CreateFrame("Frame", nil, f)
    f.statsPanel:SetPoint("TOPLEFT",  13, -50)
    f.statsPanel:SetPoint("TOPRIGHT", -13, -50)
    f.statsPanel:SetHeight(56)
    f.statsPanel:SetBackdrop(SECTION_BACKDROP)
    f.statsPanel:SetBackdropColor(0, 0, 0, 0.4)

    f.joinedText = f.statsPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.joinedText:SetPoint("TOPLEFT", 10, -8)
    f.joinedText:SetJustifyH("LEFT")

    f.lastSeenText = f.statsPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.lastSeenText:SetPoint("TOPLEFT", f.joinedText, "BOTTOMLEFT", 0, -2)
    f.lastSeenText:SetJustifyH("LEFT")

    f.zoneText = f.statsPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.zoneText:SetPoint("TOPLEFT", f.lastSeenText, "BOTTOMLEFT", 0, -2)
    f.zoneText:SetJustifyH("LEFT")

    -- ===== Public Note section =====
    local function makeNoteEditBox(parent, anchorTo, anchorOffset, maxBytes)
    local bg = CreateFrame("Frame", nil, parent)
    bg:SetPoint("TOPLEFT",  anchorTo, "BOTTOMLEFT", 0, anchorOffset)
    bg:SetPoint("TOPRIGHT", anchorTo, "BOTTOMRIGHT", 0, anchorOffset)
    bg:SetHeight(22)
    bg:SetBackdrop(INPUT_BACKDROP)
    bg:SetBackdropColor(0, 0, 0, 0.7)
    bg:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)
    local eb = CreateFrame("EditBox", nil, bg)
    eb:SetFontObject("ChatFontSmall")
    eb:SetAutoFocus(false)
    eb:SetMaxLetters(maxBytes or 31)
    eb:SetPoint("TOPLEFT", 6, -2)
    eb:SetPoint("BOTTOMRIGHT", -4, 2)
    eb:SetScript("OnEscapePressed", function(self)
    self:ClearFocus()
    refreshPanel()  -- restore original text
    end)
    return bg, eb
    end

    f.noteLabel = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.noteLabel:SetPoint("TOPLEFT", f.statsPanel, "BOTTOMLEFT", 0, -4)
    f.noteLabel:SetText("|cffffcc00 Public Note:|r  |cff888888(to save hit Enter)|r         ")
   -- f.noteLabel:SetSize(250, 20)
    f.noteBg, f.noteEdit = makeNoteEditBox(f, f.noteLabel, -4, 31)
    f.noteEdit:SetScript("OnEnterPressed", function(self)
    if not currentName then self:ClearFocus(); return end
        local idx = findRosterIndex(currentName)
        if idx and CanEditPublicNote and CanEditPublicNote() then
            GuildRosterSetPublicNote(idx, self:GetText() or "")
            if addon.RequestRosterAfterAction then addon:RequestRosterAfterAction()
                elseif addon.RequestRoster then addon:RequestRoster() else GuildRoster() end
                    end
                    self:ClearFocus()
                    end)

    -- ===== Officer Note section =====
    f.officerLabel = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.officerLabel:SetPoint("TOPLEFT", f.noteBg, "BOTTOMLEFT", 0, -4)
    f.officerLabel:SetText("|cffffcc00 Officer's Note:|r  |cff888888(to save hit Enter)|r     ")
 --   f.officerEdit:SetSize(250, 20)
    f.officerBg, f.officerEdit = makeNoteEditBox(f, f.officerLabel, 0,29)
    f.officerEdit:SetScript("OnEnterPressed", function(self)
    if not currentName then self:ClearFocus(); return end
        local idx = findRosterIndex(currentName)
        if idx and CanEditOfficerNote and CanEditOfficerNote() then
            GuildRosterSetOfficerNote(idx, self:GetText() or "")
            if addon.RequestRosterAfterAction then addon:RequestRosterAfterAction()
                elseif addon.RequestRoster then addon:RequestRoster() else GuildRoster() end
                    end
                    self:ClearFocus()
                    end)


    -- ===== Alts section =====
    f.altLabel = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.altLabel:SetPoint("TOPLEFT", f.officerBg, "BOTTOMLEFT", 0, -12)
    f.altLabel:SetText("|cffffcc00Alt Relationship|r")

    f.altStatus = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.altStatus:SetPoint("TOPLEFT", f.altLabel, "BOTTOMLEFT", 0, -3)
    f.altStatus:SetPoint("TOPRIGHT", f.officerBg, "BOTTOMRIGHT", 0, -16)
    f.altStatus:SetJustifyH("LEFT")
    f.altStatus:SetWordWrap(true)
    f.altStatus:SetHeight(28)

    -- Tag-as-alt-of input
    f.tagBg = CreateFrame("Frame", nil, f)
    f.tagBg:SetPoint("TOPLEFT", f.altStatus, "BOTTOMLEFT", 0, -10)
    f.tagBg:SetSize(120, 22)
    f.tagBg:SetBackdrop(INPUT_BACKDROP)
    f.tagBg:SetBackdropColor(0, 0, 0, 0.7)
    f.tagBg:SetBackdropBorderColor(0.5, 0.5, 0.5, 1)

    f.tagLabel = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    f.tagLabel:SetPoint("BOTTOMLEFT", f.tagBg, "TOPLEFT", 0, 1)
    f.tagLabel:SetText("Tag as alt of:")

    f.tagEdit = CreateFrame("EditBox", nil, f.tagBg)
    f.tagEdit:SetFontObject("ChatFontSmall")
    f.tagEdit:SetAutoFocus(false)
    f.tagEdit:SetPoint("TOPLEFT", 6, -3)
    f.tagEdit:SetPoint("BOTTOMRIGHT", -4, 3)
    f.tagEdit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    f.tagEdit:SetScript("OnEnterPressed",  function(self) f.btnSet:Click() end)

    f.btnSet = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    f.btnSet:SetSize(54, 22)
    f.btnSet:SetText("Set")
    f.btnSet:SetPoint("LEFT", f.tagBg, "RIGHT", 6, 0)
    f.btnSet:SetScript("OnClick", function()
        local mainName = f.tagEdit:GetText()
        if currentName and mainName and mainName ~= "" then
            local ok, msg = addon:SetAlt(currentName, mainName)
            print("|cFFFFCC00Guild Manager|r: " .. tostring(msg))
            f.tagEdit:SetText("")
            f.tagEdit:ClearFocus()
            refreshPanel()
            if addon.UI and addon.UI.RefreshIfShown then addon.UI:RefreshIfShown() end
        end
    end)

    f.btnUntag = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    f.btnUntag:SetSize(60, 22)
    f.btnUntag:SetText("Untag")
    f.btnUntag:SetPoint("LEFT", f.btnSet, "RIGHT", 4, 0)
    f.btnUntag:SetScript("OnClick", function()
        if currentName then
            local ok, msg = addon:SetAlt(currentName, nil)
            print("|cFFFFCC00GuildeaOrdo |r: " .. tostring(msg))
            refreshPanel()
            if addon.UI and addon.UI.RefreshIfShown then addon.UI:RefreshIfShown() end
        end
    end)

    -- ===== Rank buttons (Promote / Demote) =====
    f.btnPromote = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    f.btnPromote:SetSize(110, 24)
    f.btnPromote:SetText("Promote")
    f.btnPromote:SetPoint("BOTTOMLEFT", 18, 40)
    f.btnPromote:SetScript("OnClick", function()
        if not currentName then return end
        StaticPopupDialogs["GuildeaOrdo_CONFIRM_PROMOTE"] = {
            text = "Promote |cffffff00"..currentName.."|r by one rank?",
            button1 = "Promote",
            button2 = "Cancel",
            OnAccept = function()
                if GuildPromote then GuildPromote(currentName) end
                if addon.RequestRosterAfterAction then addon:RequestRosterAfterAction()
            elseif addon.RequestRoster then addon:RequestRoster() else GuildRoster() end
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
        }
        StaticPopup_Show("GuildeaOrdo_CONFIRM_PROMOTE")
    end)

    f.btnDemote = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    f.btnDemote:SetSize(110, 24)
    f.btnDemote:SetText("Demote")
    f.btnDemote:SetPoint("BOTTOMRIGHT", -18, 40)
    f.btnDemote:SetScript("OnClick", function()
        if not currentName then return end
        StaticPopupDialogs["GuildeaOrdo_CONFIRM_DEMOTE"] = {
            text = "Demote |cffffff00"..currentName.."|r by one rank?",
            button1 = "Demote",
            button2 = "Cancel",
            OnAccept = function()
                if GuildDemote then GuildDemote(currentName) end
                if addon.RequestRosterAfterAction then addon:RequestRosterAfterAction()
            elseif addon.RequestRoster then addon:RequestRoster() else GuildRoster() end
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
        }
        StaticPopup_Show("GuildeaOrdo_CONFIRM_DEMOTE")
    end)

    -- ===== Action buttons (Remove / Invite) =====
    f.btnInvite = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    f.btnInvite:SetSize(110, 24)
    f.btnInvite:SetText("Invite to Group")
    f.btnInvite:SetPoint("BOTTOMLEFT", 18, 12)
    f.btnInvite:SetScript("OnClick", function()
        if currentName and InviteUnit then
            InviteUnit(currentName)
        end
    end)

    f.btnRemove = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
    f.btnRemove:SetSize(110, 24)
    f.btnRemove:SetText("Remove from Guild")
    f.btnRemove:SetPoint("BOTTOMRIGHT", -18, 12)
    f.btnRemove:SetScript("OnClick", function()
        if not currentName then return end
        StaticPopupDialogs["GuildeaOrdo_CONFIRM_REMOVE"] = {
            text = "Remove |cffffff00"..currentName.."|r from the guild?",
            button1 = "Remove",
            button2 = "Cancel",
            OnAccept = function()
                local kicked = currentName
                if GuildUninvite and kicked then GuildUninvite(kicked) end
                -- Pre-emptively close the detail panel so the user doesn't
                -- keep staring at a now-kicked member during the brief
                -- server round-trip; the post-action refresh will reconcile
                -- the addon's roster list.
                if panel then panel:Hide() end
                if addon.RequestRosterAfterAction then
                    addon:RequestRosterAfterAction()
                end
            end,
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
            preferredIndex = 3,
        }
        StaticPopup_Show("GuildeaOrdo_CONFIRM_REMOVE")
    end)

    panel = f
    return f
end

-- =========================================================
-- Public entry point: open the detail panel for a specific
-- guild member name. Used by the addon's own Roster tab so
-- left-clicking a row mirrors clicking a name in Blizzard's
-- default roster UI.
-- =========================================================
function addon:ShowMemberDetail(name)
    if not name or name == "" then return end
    buildPanel()
    local idx = findRosterIndex(name)
    if not idx then return end

    -- Keep Blizzard's selection in sync with what we're displaying so the
    -- panel's OnUpdate poll (which reads GetGuildRosterSelection) doesn't
    -- immediately flip back to a stale selection.
    if GuildRosterSetSelection then GuildRosterSetSelection(idx) end

    currentName = name
    if not panel:IsShown() then
        panel:ClearAllPoints()
        local mainFrame = _G["GuildeaOrdoMainFrame"]
        if mainFrame and mainFrame:IsShown() then
            panel:SetPoint("TOPLEFT", mainFrame, "TOPRIGHT", -10, 0)
        elseif GuildRosterFrame and GuildRosterFrame:IsShown() then
            panel:SetPoint("TOPLEFT", GuildRosterFrame, "TOPRIGHT", -32, -10)
        else
            panel:SetPoint("CENTER")
        end
        panel:Show()
    end
    refreshPanel()
end

-- =========================================================
-- Hooking GuildMemberDetailFrame: we hide it on show and
-- pop our own panel populated for the selected member.
--
-- Important: we use GetGuildRosterSelection() (not the cached
-- text of GuildMemberDetailName) because the FontString lags
-- behind by one frame on selection changes, which made the
-- panel show stale data on the first click after switching.
-- =========================================================
local function currentSelectionName()
    local idx = GetGuildRosterSelection and GetGuildRosterSelection() or 0
    if not idx or idx <= 0 then return nil end
    return (GetGuildRosterInfo(idx))
end

local function showForCurrentSelection()
    local name = currentSelectionName()
    if not name or name == "" then return end
    currentName = name
    -- Only reposition when the panel was hidden (i.e. the user just opened
    -- it from a roster click). Once visible, leave the position alone so
    -- the user's drag is preserved and subsequent member-clicks just
    -- update the contents in place.
    if not panel:IsShown() then
        panel:ClearAllPoints()
        if GuildRosterFrame then
            panel:SetPoint("TOPLEFT", GuildRosterFrame, "TOPRIGHT", -32, -10)
        else
            panel:SetPoint("CENTER")
        end
        panel:Show()
    end
    refreshPanel()
end

local function attach()
    if not GuildMemberDetailFrame then return end
    if GuildMemberDetailFrame.__GuildeaOrdoTakeover then return end
    GuildMemberDetailFrame.__GuildeaOrdoTakeover = true

    buildPanel()

    -- Hook OnShow: every time Blizzard tries to show its detail panel,
    -- we hide that and pop ours populated from the current selection.
    GuildMemberDetailFrame:HookScript("OnShow", function(self)
        showForCurrentSelection()
        self:Hide()
    end)

    -- Hard guarantee: if Blizzard internals re-show the frame, hide it.
    GuildMemberDetailFrame:HookScript("OnUpdate", function(self)
        if self:IsShown() then self:Hide() end
    end)

    -- Tight poll on our own panel: catches selection changes that come
    -- in without a fresh OnShow (e.g. clicking a different roster row
    -- while our panel is already up).
    panel:HookScript("OnUpdate", function(self, elapsed)
        self.__GuildeaOrdoTimer = (self.__GuildeaOrdoTimer or 0) + (elapsed or 0)
        if self.__GuildeaOrdoTimer < 0.1 then return end
        self.__GuildeaOrdoTimer = 0

        local name = currentSelectionName()
        if name and name ~= currentName then
            currentName = name
            refreshPanel()
        elseif currentName then
            -- Same member - just refresh in case data changed.
            refreshPanel()
        end
    end)

    -- Clear selection cache when our panel closes.
    panel:HookScript("OnHide", function()
        currentName = nil
    end)
end

-- Retry until Blizzard's frame exists (some private cores defer XML).
local retry = CreateFrame("Frame")
retry:RegisterEvent("PLAYER_LOGIN")
retry:RegisterEvent("ADDON_LOADED")
retry:SetScript("OnEvent", function(self)
    if GuildMemberDetailFrame then
        attach()
        if GuildMemberDetailFrame.__GuildeaOrdoTakeover then
            self:UnregisterAllEvents()
        end
    end
end)
attach()
