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
    style = {
        --['background-image'] = 'url("nui://bcc-society/background.png")',
        --['background-image'] = 'url("https://i.imgur.com/7c2xBaG.png")',
        --[[['background-size'] = 'cover',
        ['background-repeat'] = 'no-repeat',
            ['background-position'] = 'center',
            ['padding'] = '50px',
            ['font-family'] = 'Courier New, monospace',
            ['color'] =  '#3e2e1e',
            ['width'] = '100%',
            ['margin'] =  '0 auto',
            ['box-shadow'] = '0 0 10px rgba(0,0,0,0.4)',]]--
    },
    contentslot = {
        style = {
            ['height'] = '450px',
            ['min-height'] = '300px'
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

-- Helper function for debugging in DevMode
if Config.devMode then
    function devPrint(...)
        local args = {...}
        local msg = "^1[DEV MODE] ^4"
        for _, v in ipairs(args) do
            msg = msg .. tostring(v) .. " "
        end
        print(msg)
    end
else
    function devPrint(...) end
end

function Notify(message, typeOrDuration, maybeDuration)
    local opts = Config.NotifyOptions or {}
    local notifyType = opts.type
    local notifyDuration = opts.autoClose
    local notifyTransition = opts.transition
    local notifyPosition = opts.position
    local hideProgress = opts.hideProgressBar

    -- Detect which argument is which
    if type(typeOrDuration) == "string" then
        notifyType = typeOrDuration
        notifyDuration = tonumber(maybeDuration) or notifyDuration
    elseif type(typeOrDuration) == "number" then
        notifyDuration = typeOrDuration
    end

    if Config.Notify == "feather-menu" then
        FeatherMenu:Notify({
            message = message,
            type = notifyType,
            autoClose = notifyDuration,
            position = notifyPosition,
            transition = notifyTransition,
            icon = true,
            hideProgressBar = hideProgress,
            rtl = false,
            style = opts.style or {},
            toastStyle = opts.toastStyle or {},
            progressStyle = opts.progressStyle or {}
        })
    elseif Config.Notify == "vorp-core" then
        -- Only message and duration supported
        Core.NotifyRightTip(message, notifyDuration)
    else
        print("^1[Notify] Invalid Config.Notify: " .. tostring(Config.Notify))
    end
end

BccUtils.RPC:Register("bcc-society:NotifyClient", function(data)
    Notify(data.message, data.type, data.duration)
end)

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
    playerListMenupage:RegisterElement("line", {
        slot = "footer",
        style = {}
    })

    playerListMenupage:RegisterElement("button", {
        label = _U("back"),
        slot = 'footer',
        style = {}
    }, function()
        backButtonCbFunct()
    end)

    playerListMenupage:RegisterElement("bottomline", {
        slot = "footer",
        style = {}
    })
    return playerListMenupage
end

function IsPlayerAdmin()
    return AdminAllowed
end