Core = exports.vorp_core:GetCore()
BccUtils = exports['bcc-utils'].initiate()

Discord = BccUtils.Discord.setup(Config.WebhookLink, Config.WebhookTitle, Config.WebhookAvatar)

-- Helper function for debugging in DevMode
if Config.devMode then
    function devPrint(...)
        local args = { ... }
        for i = 1, #args do
            if type(args[i]) == "table" then
                args[i] = json.encode(args[i])
            elseif args[i] == nil then
                args[i] = "nil"
            else
                args[i] = tostring(args[i])
            end
        end
        print("^1[DEV MODE] ^4" .. table.concat(args, " ") .. "^0")
    end
else
    function devPrint(...) end
end

function NotifyClient(src, message, type, duration)
    BccUtils.RPC:Notify("bcc-society:NotifyClient", {
        message = message,
        type = type or "info",
        duration = duration or 4000
    }, src)
end