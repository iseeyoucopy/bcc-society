Core = exports.vorp_core:GetCore()
BccUtils = exports['bcc-utils'].initiate()

Discord = BccUtils.Discord.setup(Config.WebhookLink, Config.WebhookTitle, Config.WebhookAvatar)
-- Helper function for debugging in DevMode
if Config.devMode then
    function devPrint(message)
        print("^1[DEV MODE] ^4" .. message)
    end
else
    function devPrint(message) end -- No-op if DevMode is disabled
end
