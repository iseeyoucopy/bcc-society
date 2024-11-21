RegisterServerEvent("bcc-society:BillPlayer", function(playerServerId, amount)
    local _source = source
    local billerChar = Core.getUser(_source)
    local billedChar = Core.getUser(playerServerId)
    billedChar:removeCurrency(tonumber(amount))
    billerChar:addCurrency(tonumber(amount))
    BccUtils.Discord.sendMessage(Config.adminLogsWebhook, Config.WebhookTitle, Config.WebhookAvatar, _U("playerBilled"), _U("playerBilled") .. amount)
    Core.NotifyRightTip(playerServerId, _U("youHaveBeenBilled") .. amount, 4000)
end)