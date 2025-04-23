RegisterNetEvent("bcc-society:CheckIfInSociety", function()
    local _source = source
    devPrint("[CheckIfInSociety] Triggered by source:" .. _source)

    local user = Core.getUser(_source)
    if not user then 
        devPrint("[CheckIfInSociety] No user found for source:" .. _source)
        return 
    end

    local char = user.getUsedCharacter
    if not char then 
        devPrint("[CheckIfInSociety] No character loaded for source:" .. _source)
        return 
    end

    local charId = char.charIdentifier
    devPrint("[CheckIfInSociety] Character ID:" .. tostring(charId))
    if not charId then 
        devPrint("[CheckIfInSociety] charIdentifier is nil")
        return 
    end

    local result = {
        societiesOwned = {},
        societiesEmployed = {}
    }

    local allSocsCharOwns = SocietyAPI.MiscAPI:GetAllSocietiesCharOwns(charId)
    devPrint("[CheckIfInSociety] Societies owned:" .. json.encode(allSocsCharOwns))

    if type(allSocsCharOwns) == "table" and #allSocsCharOwns > 0 then
        for _, v in pairs(allSocsCharOwns) do
            table.insert(result.societiesOwned, v)
        end
    end

    local allSocsCharEmployedAt = SocietyAPI.MiscAPI:GetAllSocietiesCharIsEmployedAt(charId)
    devPrint("[CheckIfInSociety] Societies employed at:" .. json.encode(allSocsCharEmployedAt))

    if type(allSocsCharEmployedAt) == "table" and #allSocsCharEmployedAt > 0 then
        for _, v in pairs(allSocsCharEmployedAt) do
            local society = SocietyAPI:GetSociety(v.business_id)
            if society then
                local societyData = society:GetSocietyInfo()
                if societyData then
                    table.insert(result.societiesEmployed, societyData)
                end
            end
        end
    end

    devPrint("[CheckIfInSociety] Final result being sent to client:" .. json.encode(result))
    TriggerClientEvent("bcc-society:ReceiveSocietyData", _source, result)
end)

BccUtils.RPC:Register("bcc-society:GetAllSocieties", function()
    return SocietyAPI.MiscAPI:GetAllSocieties()
end)

RegisterServerEvent("bcc-society:AdminManageSociety", function(societyId, delete, societyTax, societyName, societyInvLimit, societyBlip, societyJob)
    local _source = source
    devPrint("[AdminManageSociety] Triggered by:" .. _source .. "Society ID:" .. societyId)

    local user = Core.getUser(_source)
    if not user then 
        devPrint("[AdminManageSociety] No user for source:" .. _source)
        return 
    end

    local char = user.getUsedCharacter
    local creatorCharName = char.firstname .. " " .. char.lastname
    devPrint("[AdminManageSociety] Action by:" .. creatorCharName)

    if delete then
        devPrint("[AdminManageSociety] Deleting society:" .. societyId)
		BccUtils.Discord.sendMessage(
            Config.adminLogsWebhook,                     -- Webhook URL
            Config.WebhookTitle,                         -- Webhook title
            Config.WebhookAvatar,                        -- Webhook avatar
            _U("societyDeleted"),                        -- Embed title
            _U("societyDeletedBy") .. creatorCharName .. _U("societyId") .. societyId -- Message content
        )
        MySQL.query.await("DELETE FROM bcc_society WHERE business_id = ?", { societyId })
    else
        devPrint("[AdminManageSociety] Updating society:" .. societyId)
        MySQL.query.await("UPDATE bcc_society SET tax_amount = ?, business_name = ?, inv_limit = ?, blip_hash = ?, society_job = ? WHERE business_id = ?", {
            societyTax, societyName, societyInvLimit, societyBlip, societyJob, societyId
        })
		BccUtils.Discord.sendMessage(
            Config.adminLogsWebhook,
            Config.WebhookTitle,
            Config.WebhookAvatar,
            _U("societyUpdated"),
            _U("societyUpdatedBy") .. creatorCharName .. _U("societyId") .. societyId
        )
    end

    devPrint("[AdminManageSociety] Operation completed for society:" .. societyId)
end)

RegisterServerEvent("bcc-society:EditWebhookLink", function(societyId, webhookLink)
    MySQL.query.await("UPDATE bcc_society SET webhook_link = ? WHERE business_id = ?", { webhookLink, societyId })
end)

function GetAllOnlineChars(allData, nameSourceAndCharId)
    devPrint("[GetAllOnlineChars] Fetching online characters...")

    local allOnlineChars = {} -- Replace this with actual logic
    if #allOnlineChars > 0 then
        local allLoopedSources = {}
        for k, v in pairs(allOnlineChars) do
            if not GetPlayerPed(v.playerSource) then
                devPrint("[GetAllOnlineChars] Player source has no ped, removing:" .. v.playerSource)
                table.remove(allOnlineChars, k)
                break
            end
            if #allLoopedSources > 0 then
                for e, a in pairs(allLoopedSources) do
                    if a == v.playerSource then
                        devPrint("[GetAllOnlineChars] Duplicate source, removing:" .. v.playerSource)
                        table.remove(allOnlineChars, k)
                    end
                end
            end
            table.insert(allLoopedSources, v.playerSource)
        end

        if #allOnlineChars > 0 then
            if allData then
                devPrint("[GetAllOnlineChars] Returning full data")
                return allOnlineChars
            elseif nameSourceAndCharId == true then
                local sortedInfo = {}
                for k, v in pairs(allOnlineChars) do
                    table.insert(sortedInfo, {
                        name = v.user.getUsedCharacter.firstname .. " " .. v.user.getUsedCharacter.lastname,
                        source = v.playerSource,
                        charId = v.user.getUsedCharacter.charIdentifier
                    })
                end
                devPrint("[GetAllOnlineChars] Returning name/source/charId")
                return sortedInfo
            end
        end
    else
        devPrint("[GetAllOnlineChars] No online characters found")
        return false
    end
end
