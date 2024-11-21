DBUpdated = false

BccUtils.RPC:Register("BCC-Society:AdminCheck", function(params, cb, recSource)

    local user = Core.getUser(recSource)
    local character = user.getUsedCharacter

    if not character then
        return cb(false)
    end
    if character.group == Config.adminGroup then
        return cb(true)
    end
    return cb(false)
end)

BccUtils.RPC:Register("BCC-Society:GetPlayers", function(params, cb, recSource)
    local data = {}
    local players = GetPlayers() -- Fetch all current players on the server

    if players and #players > 0 then
        for _, playerId in ipairs(players) do
            local User = Core.getUser(playerId)
            if User then
                local Character = User.getUsedCharacter
                if Character then
                    -- Check if firstname and lastname are not nil and provide default values if they are
                    local firstname = Character.firstname or "Unknown"
                    local lastname = Character.lastname or "Player"
                    local playerName = firstname .. ' ' .. lastname
                    data[tostring(playerId)] = {
                        serverId = playerId,
                        PlayerName = playerName,
                        staticid = Character.charIdentifier,
                    }
                end
            end
        end
    end

    cb(data) -- Return player data via callback
end)

BccUtils.Versioner.checkFile(GetCurrentResourceName(), 'https://github.com/BryceCanyonCounty/bcc-society')