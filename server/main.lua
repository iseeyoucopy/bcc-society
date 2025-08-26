DBUpdated = false

BccUtils.RPC:Register("BCC-Society:AdminCheck", function(_, cb, src)
    local user = Core.getUser(src)
    if not user then
        devPrint("[ERROR] User not found for source: " .. tostring(src))
        return cb(false)
    end

    local character = user.getUsedCharacter
    if not character then
        devPrint("[ERROR] Character not found for user: " .. tostring(src))
        return cb(false)
    end

    devPrint("[AdminCheck] Checking admin for charId " .. tostring(character.charIdentifier) ..
             " (Group: " .. tostring(character.group) .. ")")

    -- ✅ Check group
    for _, group in ipairs(Config.adminGroups or {}) do
        if character.group == group then
            devPrint("[AdminCheck] Matched admin group: " .. tostring(group))
            return cb(true)
        end
    end

        -- Check job
    for _, job in ipairs(Config.AllowedJobs or {}) do
        if character.job == job then
            return cb(true)
        end
    end

    devPrint("[AdminCheck] No matching admin group found.")
    devPrint("[AdminCheck] Access denied for src " .. tostring(src))
    return cb(false)
end)

BccUtils.RPC:Register("BCC-Society:GetPlayers", function(params, cb, recSource)
    devPrint("[GetPlayers] RPC invoked by src", tostring(recSource))

    local data    = {}
    local players = GetPlayers()

    devPrint("[GetPlayers] Players table length:", players and tostring(#players) or "nil")

    if not players or #players == 0 then
        devPrint("[GetPlayers] No players found on server.")
        cb(data)
        return
    end

    local added = 0

    for _, playerId in ipairs(players) do
        local pidStr = tostring(playerId)
        devPrint("[GetPlayers] Inspecting playerId:", pidStr)

        local User = Core.getUser(playerId)
        if not User then
            devPrint("[GetPlayers] Core.getUser returned nil for", pidStr)
        else
            local Character = User.getUsedCharacter
            if not Character then
                devPrint("[GetPlayers] getUsedCharacter is nil for", pidStr)
            else
                local firstname = Character.firstname or "Unknown"
                local lastname  = Character.lastname or "Player"
                if (Character.firstname == nil) or (Character.lastname == nil) then
                    devPrint("[GetPlayers] Missing name parts for", pidStr, "-> using:", firstname, lastname)
                end

                local playerName = firstname .. " " .. lastname
                local staticid   = Character.charIdentifier

                devPrint("[GetPlayers] Adding player to list:", pidStr,
                         "name:", playerName,
                         "charId:", tostring(staticid))

                data[pidStr] = {
                    serverId   = playerId,
                    PlayerName = playerName,
                    staticid   = staticid,
                }
                added = added + 1
            end
        end
    end

    devPrint("[GetPlayers] Completed. Added", tostring(added), "of", tostring(#players), "players.")
    cb(data)
end)

BccUtils.Versioner.checkFile(GetCurrentResourceName(), 'https://github.com/BryceCanyonCounty/bcc-society')