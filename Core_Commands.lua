-- GuildeaOrdo Slash Commands
local addon = GuildeaOrdo

SLASH_GuildeaOrdo1 = "/GuildeaOrdo"
SLASH_GuildeaOrdo2 = "/go"
SlashCmdList["GuildeaOrdo"] = function(msg)
    msg = msg or ""
    local cmd, rest = string.match(msg, "^(%S+)%s*(.*)$")
    cmd = (cmd or ""):lower()
    local arg = rest or ""

    if cmd == "" or cmd == "ui" or cmd == "toggle" then
        if addon.UI and addon.UI.Toggle then addon.UI:Toggle() end
    elseif cmd == "bladd" or cmd == "addbl" or cmd == "blackadd" then
        if arg ~= "" then
            if addon.AddToBlacklist then
                addon:AddToBlacklist(arg)
                print("|cFFFFCC00GuildeaOrdo|r: Added |cffffffff" .. arg .. "|r to blacklist.")
            end
        else
            print("|cFFFFCC00GuildeaOrdo|r: Usage: /go bladd PlayerName")
        end
    elseif cmd == "bl" or cmd == "blist" or cmd == "blacklist" or cmd == "black" then
        if addon.GetBlacklist then
            local list = addon:GetBlacklist()
            if #list == 0 then
                print("|cFFFFCC00GuildeaOrdo|r: Blacklist is empty.")
            else
                local displayList = {}
                for _, n in ipairs(list) do
                    table.insert(displayList, n:sub(1,1):upper() .. n:sub(2))
                end
                print("|cFFFFCC00GuildeaOrdo|r: Blacklist (" .. #list .. "): |cffffffff" .. table.concat(displayList, ", ") .. "|r")
            end
        end
        
    -- NEW: Checked Guild Invite (Specific Player)
    elseif cmd == "inv" then
        if arg ~= "" then
            if addon:IsBlacklisted(arg) then
                print("|cFFFFCC00GuildeaOrdo|r: Invite blocked. |cffffffff" .. arg .. "|r is currently blacklisted.")
            else
                GuildInvite(arg)
                print("|cFFFFCC00GuildeaOrdo|r: Checked Guild Invite sent to |cffffffff" .. arg .. "|r.")
            end
        else
            print("|cFFFFCC00GuildeaOrdo|r: Usage: /go inv PlayerName")
        end

    -- NEW: Checked Guild Invite (Last Whisperer)
    elseif cmd == "invl" then
        local target = addon.lastWhisperedPlayer
        if target and target ~= "" then
            if addon:IsBlacklisted(target) then
                print("|cFFFFCC00GuildeaOrdo|r: Invite blocked. Last whisperer (|cffffffff" .. target .. "|r) is blacklisted.")
            else
                GuildInvite(target)
                print("|cFFFFCC00GuildeaOrdo|r: Checked Guild Invite sent to last whisperer (|cffffffff" .. target .. "|r).")
            end
        else
            print("|cFFFFCC00GuildeaOrdo|r: No recent whisperer found to invite.")
        end

    elseif cmd == "help" then
        print("|cFFFFCC00GuildeaOrdo commands:|r")
        print("  /go or /GuildeaOrdo - Toggle main window")
        print("  /go bladd <name> - Add player to blacklist (Auto Guild/Group Invite)")
        print("  /go bl or /go blacklist - Show current blacklist in chat")
        print("  /go inv <name> - Safely invite a player (checks blacklist first)")
        print("  /go invl - Safely invite the last player who whispered you")
    else
        -- unknown, just toggle UI
        if addon.UI and addon.UI.Toggle then addon.UI:Toggle() end
    end
end