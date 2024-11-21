RegisterServerEvent("bcc-society:RankManagement", function(type, businessId, rankName, rankLabel, rankPay, payIncrement, toggleBlip, withdraw, deposit, editRanks, manageEmployees, openInventory, editWebhook, canManageStore, rankJobGrade, rankCanBillPlayers)
    local _source = source
    local user = Core.getUser(_source)
    if not user then return end
    local char = user.getUsedCharacter
    local fullName = char.firstname .. " " .. char.lastname
    local webhookLink = MySQL.query.await("SELECT * FROM bcc_society WHERE business_id = ?", { businessId })
    if not tonumber(rankJobGrade) then -- Default value if it's not a number
        rankJobGrade = 0
    end

    local rankInfo = "**Rank Information**\n" ..
        "- **Name**: " .. rankName .. "\n" ..
        "- **Label**: " .. rankLabel .. "\n" ..
        "- **Grade**: " .. rankJobGrade .. "\n" ..
        "- **Business ID**: " .. businessId

    local permissionsList = "**Permissions**:\n" ..
        "- " .. _U("canToggleBlip") .. ": " .. (toggleBlip == "true" and "✅" or "❌") .. "\n" ..
        "- " .. _U("canWithdraw") .. ": " .. (withdraw == "true" and "✅" or "❌") .. "\n" ..
        "- " .. _U("canDeposit") .. ": " .. (deposit == "true" and "✅" or "❌") .. "\n" ..
        "- " .. _U("canEditRanks") .. ": " .. (editRanks == "true" and "✅" or "❌") .. "\n" ..
        "- " .. _U("canManageEmployees") .. ": " .. (manageEmployees == "true" and "✅" or "❌") .. "\n" ..
        "- " .. _U("canOpenInventory") .. ": " .. (openInventory == "true" and "✅" or "❌") .. "\n" ..
        "- " .. _U("canEditWebhook") .. ": " .. (editWebhook == "true" and "✅" or "❌")

    if type == "add" then
        local retval = MySQL.query.await("SELECT * FROM bcc_society_ranks WHERE business_id = ?", { businessId })
        if #retval > 0 then
            local insert = true
            for _, v in pairs(retval) do
                if v.rank_name == rankName then
                    insert = false
                    break
                end
            end
            if insert then
                BccUtils.Discord.sendMessage(
                    webhookLink[1].webhook_link,
                    Config.WebhookTitle,
                    Config.WebhookAvatar,
                    _U("rankMade"),
                    "**" .. _U("rankMadeBy") .. "** " .. fullName .. "\n" .. rankInfo .. "\n" .. permissionsList
                )
                MySQL.query.await("INSERT INTO bcc_society_ranks (business_id, rank_name, rank_label, rank_pay, rank_pay_increment, rank_can_toggle_blip, rank_can_withdraw, rank_can_deposit, rank_can_edit_ranks, rank_can_manage_employees, rank_can_open_inventory, rank_can_edit_webhook_link, rank_can_manage_store, society_job_rank, rank_can_bill_players) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
                    { businessId, rankName, rankLabel, rankPay, payIncrement, toggleBlip, withdraw, deposit, editRanks, manageEmployees, openInventory, editWebhook, canManageStore, rankJobGrade, rankCanBillPlayers })
                Core.NotifyRightTip(_source, _U("rankCreated"), 4000)
            else
                Core.NotifyRightTip(_source, _U("rankExists"), 4000)
            end
        else
            BccUtils.Discord.sendMessage(
                webhookLink[1].webhook_link,
                Config.WebhookTitle,
                Config.WebhookAvatar,
                _U("rankMade"),
                "**" .. _U("rankMadeBy") .. "** " .. fullName .. "\n" .. rankInfo .. "\n" .. permissionsList
            )
            MySQL.query.await("INSERT INTO bcc_society_ranks (business_id, rank_name, rank_label, rank_pay, rank_pay_increment, rank_can_toggle_blip, rank_can_withdraw, rank_can_deposit, rank_can_edit_ranks, rank_can_manage_employees, rank_can_open_inventory, rank_can_edit_webhook_link, rank_can_manage_store, society_job_rank, rank_can_bill_players) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
                { businessId, rankName, rankLabel, rankPay, payIncrement, toggleBlip, withdraw, deposit, editRanks, manageEmployees, openInventory, editWebhook, canManageStore, rankJobGrade, rankCanBillPlayers })
            Core.NotifyRightTip(_source, _U("rankCreated"), 4000)
        end
    elseif type == "update" then
        local retval = MySQL.query.await("SELECT * FROM bcc_society_ranks WHERE business_id = ? AND rank_name = ?", { businessId, rankName })
        if #retval > 0 then
            BccUtils.Discord.sendMessage(
                webhookLink[1].webhook_link,
                Config.WebhookTitle,
                Config.WebhookAvatar,
                _U("rankUpdated"),
                "**" .. _U("rankUpdatedBy") .. "** " .. fullName .. "\n" .. rankInfo .. "\n" .. permissionsList
            )
            MySQL.query.await("UPDATE bcc_society_ranks SET rank_label = ?, rank_pay = ?, rank_pay_increment = ?, rank_can_toggle_blip = ?, rank_can_withdraw = ?, rank_can_deposit = ?, rank_can_edit_ranks = ?, rank_can_manage_employees = ?, rank_can_open_inventory = ?, rank_can_edit_webhook_link = ?, rank_can_manage_store = ?, society_job_rank = ?, rank_can_bill_players = ? WHERE business_id = ? AND rank_name = ?",
                { rankLabel, rankPay, payIncrement, toggleBlip, withdraw, deposit, editRanks, manageEmployees, openInventory, editWebhook, canManageStore, rankJobGrade, rankCanBillPlayers, businessId, rankName })
            Core.NotifyRightTip(_source, _U("rankUpdated"), 4000)
        end
    elseif type == "delete" then
        local retval = MySQL.query.await("SELECT * FROM bcc_society_ranks WHERE business_id = ? AND rank_name = ?", { businessId, rankName })
        if #retval > 0 then
            MySQL.query.await("DELETE FROM bcc_society_ranks WHERE business_id = ? AND rank_name = ?", { businessId, rankName })
            Core.NotifyRightTip(_source, _U("rankDeleted"), 4000)
            
            -- Send a Discord notification
            BccUtils.Discord.sendMessage(
                webhookLink[1].webhook_link,
                Config.WebhookTitle,
                Config.WebhookAvatar,
                _U("rankDeleted"),
                "**" .. _U("rankDeletedBy") .. "** " .. fullName .. "\n" ..
                "- **" .. _U("rankName") .. ":** " .. rankName .. "\n" ..
                "- **Business ID**: " .. businessId
            )
        end
    end    
end)

BccUtils.RPC:Register("bcc-society:GetAllRanks", function(params, cb, recSource)
    local societyRanks = SocietyAPI:GetSociety(params.socId):GetAllRanks()
    if societyRanks then
        return cb(societyRanks)
    else
        return cb(false)
    end
end)
