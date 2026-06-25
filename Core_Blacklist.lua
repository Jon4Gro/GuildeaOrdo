-- GildeaOrdo Blacklist API (account-wide, used by both Auto Guild Invite and Auto Group Invite)
local addon = GildeaOrdo

function addon:AddToBlacklist(name, note)
    if not name or name == "" then return false end
    GildeaOrdoDB.blacklist = GildeaOrdoDB.blacklist or {}
    local clean = strsplit("-", name or ""):lower()
    if clean == "" then return false end
    local prev = GildeaOrdoDB.blacklist[clean]
    if note and note ~= "" then
        GildeaOrdoDB.blacklist[clean] = note
    else
        if prev == nil or type(prev) == "boolean" then
            GildeaOrdoDB.blacklist[clean] = ""
        end
    end
    if addon.UI and addon.UI.RefreshBlacklistWindow then addon.UI:RefreshBlacklistWindow() end
    if addon.UI and addon.UI.RefreshBlacklistDetail then addon.UI:RefreshBlacklistDetail() end
    return true
end

function addon:RemoveFromBlacklist(name)
    if not name or not GildeaOrdoDB or not GildeaOrdoDB.blacklist then return end
    local clean = strsplit("-", name or ""):lower()
    GildeaOrdoDB.blacklist[clean] = nil
    if addon.UI and addon.UI.RefreshBlacklistWindow then addon.UI:RefreshBlacklistWindow() end
    if addon.UI and addon.UI.HideBlacklistDetail then addon.UI:HideBlacklistDetail() end
end

function addon:ClearBlacklist()
    if not GildeaOrdoDB or not GildeaOrdoDB.blacklist then return end
    GildeaOrdoDB.blacklist = {}
    if addon.UI and addon.UI.RefreshBlacklistWindow then addon.UI:RefreshBlacklistWindow() end
    if addon.UI and addon.UI.HideBlacklistDetail then addon.UI:HideBlacklistDetail() end
end

function addon:IsBlacklisted(name)
    if not name or not GildeaOrdoDB or not GildeaOrdoDB.blacklist then return false end
    local clean = strsplit("-", name or ""):lower()
    return GildeaOrdoDB.blacklist[clean] ~= nil
end

function addon:GetBlacklist(filterText)
    if not GildeaOrdoDB or not GildeaOrdoDB.blacklist then return {} end
    local list = {}
    local filter = filterText and filterText:lower():match("^%s*(.-)%s*$") or ""
    
    for k in pairs(GildeaOrdoDB.blacklist) do
        if filter == "" or k:find(filter, 1, true) then
            table.insert(list, k)
        end
    end
    table.sort(list)
    return list
end

function addon:GetBlacklistNote(name)
    if not name or not GildeaOrdoDB or not GildeaOrdoDB.blacklist then return "" end
    local clean = strsplit("-", name or ""):lower()
    local v = GildeaOrdoDB.blacklist[clean]
    if type(v) == "string" then return v end
    return ""
end

function addon:SetBlacklistNote(name, noteText)
    if not name or name == "" then return end
    GildeaOrdoDB.blacklist = GildeaOrdoDB.blacklist or {}
    local clean = strsplit("-", name or ""):lower()
    if clean == "" then return end
    if GildeaOrdoDB.blacklist[clean] == nil then return end
    GildeaOrdoDB.blacklist[clean] = noteText or ""
    if addon.UI and addon.UI.RefreshBlacklistDetail then addon.UI:RefreshBlacklistDetail() end
end

function addon:GetBlacklistReply()
    return (GildeaOrdoDB and GildeaOrdoDB.blacklistReply) or ""
end

function addon:SetBlacklistReply(text)
    if GildeaOrdoDB then
        GildeaOrdoDB.blacklistReply = text or ""
    end
end

function addon:ShareBlacklist()
    if not GildeaOrdoDB or not GildeaOrdoDB.blacklist or next(GildeaOrdoDB.blacklist) == nil then
        print("|cFFFFCC00GildeaOrdo|r: Blacklist is empty.")
        return
    end

    local entries = {}
    for nameLower, note in pairs(GildeaOrdoDB.blacklist) do
        local display = nameLower:sub(1,1):upper() .. nameLower:sub(2)
        local noteStr = note or ""
        if type(noteStr) ~= "string" then noteStr = "" end
        local displayEntry
        if noteStr ~= "" then
            displayEntry = display .. " (" .. noteStr .. ")"
        else
            displayEntry = display
        end
        table.insert(entries, displayEntry)
    end
    table.sort(entries)

    if #entries == 0 then
        print("|cFFFFCC00GildeaOrdo|r: Blacklist is empty.")
        return
    end

    SendChatMessage("GildeaOrdo Blacklist share:", "OFFICER")

    local blMessages = {}
    local current = "GildeaOrdo BL: "
    local MAX_MSG_LEN = 220
    for i, entry in ipairs(entries) do
        local sep = (#current > #("GildeaOrdo BL: ")) and "||" or ""
        local addition = sep .. entry
        if #current + #addition > MAX_MSG_LEN then
            table.insert(blMessages, current)
            current = "GildeaOrdo BL: " .. entry
        else
            current = current .. addition
        end
    end
    if #current > #("GildeaOrdo BL: ") then
        table.insert(blMessages, current)
    end

    local msgIndex = 1
    local function sendBurst()
        local sent = 0
        while msgIndex <= #blMessages and sent < 5 do
            SendChatMessage(blMessages[msgIndex], "OFFICER")
            msgIndex = msgIndex + 1
            sent = sent + 1
        end
        if msgIndex <= #blMessages then
            addon:delayCall(2.1, sendBurst)
        end
    end

    if #blMessages > 0 then sendBurst() end
    print("|cFFFFCC00GildeaOrdo|r: Shared " .. #entries .. " blacklisted members (with notes) to Officer chat.")
end