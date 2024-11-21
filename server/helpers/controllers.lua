RegisterNetEvent("bcc-society:CheckIfInSociety", function()
    local _source = source
    local user = Core.getUser(_source)
    if not user then return end

    local char = user.getUsedCharacter
    if not char then return end

    local charId = char.charIdentifier
    local result = {
        societiesOwned = {},
        societiesEmployed = {}
    }

    -- Collect all societies the character owns
    local allSocsCharOwns = SocietyAPI.MiscAPI:GetAllSocietiesCharOwns(charId)
    if type(allSocsCharOwns) == "table" and #allSocsCharOwns > 0 then
        for _, v in pairs(allSocsCharOwns) do
            table.insert(result.societiesOwned, v)
        end
    end

    -- Collect all societies the character is employed at
    local allSocsCharEmployedAt = SocietyAPI.MiscAPI:GetAllSocietiesCharIsEmployedAt(charId)
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

    -- Send the result back to the client
    --print("[bcc-society:CheckIfInSociety] Sending society data to client:", json.encode(result))
    TriggerClientEvent("bcc-society:ReceiveSocietyData", _source, result)
end)

BccUtils.RPC:Register("bcc-society:GetAllSocieties", function()
    return SocietyAPI.MiscAPI:GetAllSocieties()
end)

RegisterServerEvent("bcc-society:AdminManageSociety", function(societyId, delete, societyTax, societyName, societyInvLimit, societyBlip, societyJob)
    local _source = source
    local user = Core.getUser(_source)
    if not user then return end
    local char = user.getUsedCharacter
    local creatorCharName = char.firstname .. "" .. char.lastname
    if delete then
        BccUtils.Discord.sendMessage(
            Config.adminLogsWebhook,                     -- Webhook URL
            Config.WebhookTitle,                         -- Webhook title
            Config.WebhookAvatar,                        -- Webhook avatar
            _U("societyDeleted"),                        -- Embed title
            _U("societyDeletedBy") .. creatorCharName .. _U("societyId") .. societyId -- Message content
        )
        MySQL.query.await("DELETE FROM bcc_society WHERE business_id = ?", { societyId })
    else
        MySQL.query.await("UPDATE bcc_society SET tax_amount = ?, business_name = ?, inv_limit = ?, blip_hash = ?, society_job = ? WHERE business_id = ?", { societyTax, societyName, societyInvLimit, societyBlip, societyJob, societyId })
        BccUtils.Discord.sendMessage(
            Config.adminLogsWebhook,
            Config.WebhookTitle,
            Config.WebhookAvatar,
            _U("societyUpdated"),
            _U("societyUpdatedBy") .. creatorCharName .. _U("societyId") .. societyId
        )
    end    
end)

RegisterServerEvent("bcc-society:EditWebhookLink", function(societyId, webhookLink)
    MySQL.query.await("UPDATE bcc_society SET webhook_link = ? WHERE business_id = ?", { webhookLink, societyId })
end)

function GetAllOnlineChars(allData, nameSourceAndCharId)
    local allOnlineChars = {} -- Replace this with your actual method to get all online characters
    if #allOnlineChars > 0 then
        local allLoopedSources = {}
        for k, v in pairs(allOnlineChars) do
            if not GetPlayerPed(v.playerSource) then
                table.remove(allOnlineChars, k)
                break
            end
            if #allLoopedSources > 0 then
                for e, a in pairs(allLoopedSources) do
                    if a == v.playerSource then
                        table.remove(allOnlineChars, k)
                    end
                end
            end
            table.insert(allLoopedSources, v.playerSource)
        end
        if #allOnlineChars > 0 then
            if allData then
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
                return sortedInfo
            end
        else
            return false
        end
    else
        return false
    end
end