FeatherMenu = exports['feather-menu'].initiate()
Core = exports.vorp_core:GetCore()
BccUtils = exports['bcc-utils'].initiate()

--Global Vars
BCCSocietyMenu = FeatherMenu:RegisterMenu('BCC-Society:Menu', {
    top = '3%',
    left = '3%',
    ['720width'] = '400px',
    ['1080width'] = '500px',
    ['2kwidth'] = '600px',
    ['4kwidth'] = '800px',
    style = {},
    contentslot = {
        style = {
            ['height'] = '350px',
            ['min-height'] = '250px'
        }
    },
    draggable = true,
    canclose = true
}, {
    opened = function()
        DisplayRadar(false)
    end,
    closed = function()
        DisplayRadar(true)
    end
})


-- Function to create and display the player list menu
function GetPlayerListMenuPage(exclusionList, playerChosenCbFunct, backButtonCbFunct)
    local allPlayers = BccUtils.RPC:CallAsync("BCC-Society:GetPlayers")
    --print("All Players Data:", json.encode(allPlayers))  -- Confirm player data

    if not allPlayers or next(allPlayers) == nil then
        --print("No players received from RPC call")
        return nil
    end

    local playerListMenupage = BCCSocietyMenu:RegisterPage("bcc-society:playerListMenupage")
    playerListMenupage:RegisterElement("header", {
        value = _U("playerList"),
        slot = "header",
        style = {}
    })

    for k, v in pairs(allPlayers) do
        local exclude = false
        if exclusionList then
            for _, l in pairs(exclusionList) do
                if tonumber(v.staticid) == tonumber(l.charId) or tonumber(v.serverId) == tonumber(l.source) then
                    exclude = true
                    --print("Excluding player:", v.PlayerName, "ID:", v.staticid)  -- Debug exclusion
                    break
                end
            end
        end

        if not exclude then
            --print("Adding player to menu:", v.PlayerName, "ID:", v.staticid)  -- Confirm player addition
            playerListMenupage:RegisterElement("button", {
                label = v.PlayerName,
                style = {}
            }, function()
                --print("Player chosen:", v.PlayerName, "Char ID:", v.staticid, "Source:", v.serverId) -- Confirm selected data
                playerChosenCbFunct({
                    charId = v.staticid,
                    source = v.serverId
                })
            end)
        end
    end

    playerListMenupage:RegisterElement("button", {
        label = _U("back"),
        slot = 'footer',
        style = {}
    }, function()
        backButtonCbFunct()
    end)

    return playerListMenupage
end
