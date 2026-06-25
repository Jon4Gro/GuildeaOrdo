-- GildeaOrdo Slash Commands
local addon = GildeaOrdo

SLASH_GILDEAORDO1 = "/gildeaordo"
SLASH_GILDEAORDO2 = "/go"
SlashCmdList["GILDEAORDO"] = function(msg)
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
                print("|cFFFFCC00GildeaOrdo|r: Added |cffffffff" .. arg .. "|r to blacklist.")
            end
        else
            print("|cFFFFCC00GildeaOrdo|r: Usage: /go bladd PlayerName")
        end
    elseif cmd == "bl" or cmd == "blist" or cmd == "blacklist" or cmd == "black" then
        if addon.GetBlacklist then
            local list = addon:GetBlacklist()
            if #list == 0 then
                print("|cFFFFCC00GildeaOrdo|r: Blacklist is empty.")
            else
                local displayList = {}
                for _, n in ipairs(list) do
                    table.insert(displayList, n:sub(1,1):upper() .. n:sub(2))
                end
                print("|cFFFFCC00GildeaOrdo|r: Blacklist (" .. #list .. "): |cffffffff" .. table.concat(displayList, ", ") .. "|r")
            end
        end
    elseif cmd == "help" then
        print("|cFFFFCC00GildeaOrdo commands:|r")
        print("  /go or /gildeaordo - Toggle main window")
        print("  /go bladd <name> - Add player to blacklist (Auto Guild/Group Invite)")
        print("  /go bl or /go blacklist - Show current blacklist in chat")
    else
        -- unknown, just toggle UI
        if addon.UI and addon.UI.Toggle then addon.UI:Toggle() end
    end
end
