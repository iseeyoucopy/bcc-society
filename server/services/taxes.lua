CreateThread(function()        --Tax handling
    if Config.taxesEnabled then
        while not DBUpdated do -- Waiting for db to be updated before running (While this should never cause errors this is a safety measure)
            Wait(1000)
        end
        local date = os.date("%d")
        local retval = MySQL.query.await("SELECT * FROM bcc_society")
        if tonumber(date) == tonumber(Config.taxDay) then --for some reason these have to be tonumbered
            if #retval > 0 then
                for k, v in pairs(retval) do
                    if v.taxes_paid == 'false' then
                        if tonumber(v.ledger) < tonumber(v.tax_amount) then
                            -- Send webhook notification for tax payment success to admin logs and society webhook
                            BccUtils.Discord.sendMessage(
                                Config.adminLogsWebhook,
                                Config.WebhookTitle,
                                Config.WebhookAvatar,
                                _U("taxesPaid"),
                                _U("taxesPaidBy") .. v.business_id
                            )
                            BccUtils.Discord.sendMessage(
                                v.webhook_link,
                                Config.WebhookTitle,
                                Config.WebhookAvatar,
                                _U("taxesPaid"),
                                _U("taxesPaid")
                            )
                            MySQL.query.await("DELETE FROM bcc_society WHERE business_id = ?", { v.business_id })
                        else
                            -- Send webhook notification for tax payment failure to admin logs and society webhook
                            BccUtils.Discord.sendMessage(
                                Config.adminLogsWebhook,
                                Config.WebhookTitle,
                                Config.WebhookAvatar,
                                _U("taxesFailed"),
                                _U("taxesFailedBy") .. v.business_id
                            )
                            BccUtils.Discord.sendMessage(
                                v.webhook_link,
                                Config.WebhookTitle,
                                Config.WebhookAvatar,
                                _U("taxesFailed"),
                                _U("taxesFailed")
                            )
                            MySQL.query.await(
                                "UPDATE bcc_society SET ledger = ledger - ?, taxes_paid = 'true' WHERE business_id = ?",
                                { tonumber(v.tax_amount), v.business_id }
                            )
                        end
                    end
                end
            end
        elseif tonumber(date) == tonumber(Config.taxResetDay) then
            if #retval > 0 then
                for k, v in pairs(retval) do
                    MySQL.query.await("UPDATE bcc_society SET taxes_paid = 'false' WHERE business_id = ?",
                        { v.business_id })
                end
            end
        end
    end
end)
