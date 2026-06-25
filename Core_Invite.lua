-- GildeaOrdo Auto-Invite & Group-Invite Logic
local addon = GildeaOrdo

-- =========================================================
-- Helper: Multiple Trigger Words separated by '-'
-- =========================================================
local function containsTriggerWord(msg, triggerString)
    if not triggerString or triggerString == "" then return false end
    local lowerMsg = msg:lower()
    for word in string.gmatch(triggerString, "([^%-]+)") do
        word = word:match("^%s*(.-)%s*$") -- trim whitespace
        if word ~= "" and lowerMsg:find(word:lower(), 1, true) then
            return true
        end
    end
    return false
end

-- =========================================================
-- Pre-invite /who level check
-- =========================================================
function addon:ProcessWhoLevelCheck()
    addon.pendingLevelChecks = addon.pendingLevelChecks or {}
    if next(addon.pendingLevelChecks) == nil then return end

    local num = GetNumWhoResults()
    if num == 0 then return end

    local conf = GildeaOrdoDB and GildeaOrdoCharDB.autoInvite
    if not conf then 
        addon.pendingLevelChecks = {}
        return 
    end

    local minL = tonumber(conf.minLvl) or 1

    -- Loop through silent who buffer to match the player who whispered us
    for i = 1, num do
        local whoName, _, whoLevelRaw = GetWhoInfo(i)
        if whoName then
            -- Clean the incoming WhoName (strip cross-realm strings, force lowercase)
            local cleanWhoName = string.lower(strsplit("-", whoName))
            
            -- Check if this matches an item in our lookup checklist
            local originalSender = addon.pendingLevelChecks[cleanWhoName]
            
            if originalSender then
                local whoLevel = tonumber(whoLevelRaw) or 0
                addon.pendingLevelChecks[cleanWhoName] = nil -- Clear entry immediately

                if whoLevel >= minL then
                    if conf.replyOn and conf.replyOn ~= "" then
                        SendChatMessage(conf.replyOn, "WHISPER", nil, originalSender)
                    end
                    GuildInvite(originalSender)
                else
                    if conf.replyLow and conf.replyLow ~= "" then
                        SendChatMessage(conf.replyLow, "WHISPER", nil, originalSender)
                    end
                end
            end
        end
    end

    -- After handling our silent level-check /who, hide the Blizzard Who/FriendsFrame
    -- Revert panel configurations back to the player's snapshot state
    if addon._friendsFrameShown ~= nil then
        if addon._friendsFrameShown then
            -- If they were viewing the social panel, click back to their target sub-tab smoothly
            if addon._friendsFrameTab and PanelTemplates_GetSelectedTab(FriendsFrame) ~= addon._friendsFrameTab then
                PanelTemplates_SetTab(FriendsFrame, addon._friendsFrameTab)
                if FriendsFrame_Update then FriendsFrame_Update() end
                    end
                    else
                        -- Dismiss the layout frame properly using the UI manager, not a brute-force :Hide()
                        if FriendsFrame and FriendsFrame:IsShown() then
                            HideUIPanel(FriendsFrame)
                            end

                            -- Restore other panels that were pushed off-screen or closed
                            if addon._savedPanels then
                                local function restorePanel(panel)
                                if panel and panel ~= FriendsFrame and not panel:IsShown() then
                                    ShowUIPanel(panel)
                                    end
                                    end

                                    restorePanel(addon._savedPanels.fullscreen)
                                    restorePanel(addon._savedPanels.doublewide)
                                    restorePanel(addon._savedPanels.left)
                                    restorePanel(addon._savedPanels.center)
                                    restorePanel(addon._savedPanels.right)
                                    end
                                    end

                                    -- Flush snapshot allocations
                                    addon._friendsFrameShown = nil
                                    addon._friendsFrameTab = nil
                                    addon._savedPanels = nil
                                    end
                                    end
-- =========================================================
-- Group Auto-Invite Feature API
-- =========================================================
addon.groupInviteActive = false
addon.groupInvitePermanent = false

function addon:StartGroupInvite(minutes)
    self.groupInviteActive = true
    print("|cFFFFCC00GildeaOrdo|r: Group Auto-Invite mode enabled.")
    if not self.groupInvitePermanent then
        local mins = tonumber(minutes) or 15
        if mins > 0 then
            addon:delayCall(mins * 60, function()
                if self.groupInviteActive and not self.groupInvitePermanent then
                    self:StopGroupInvite()
                end
            end)
        end
    end
end

function addon:StopGroupInvite()
    self.groupInviteActive = false
    print("|cFFFFCC00GildeaOrdo|r: Group Auto-Invite mode disabled.")
    if addon.UI and addon.UI.RefreshIfShown then addon.UI:RefreshIfShown() end
end

-- Expose helper
addon.containsTriggerWord = containsTriggerWord
