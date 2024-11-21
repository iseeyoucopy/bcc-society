local inventoriesRegistered = {}

RegisterServerEvent('bcc-society:openInventory', function(businessId, businessName, limit, currentStage)
    local _source = source
    local inventoryId = "BCC-Society" .. businessId

    -- Register the inventory if it’s not already registered
    if not inventoriesRegistered[businessId] then
        local isRegistered = exports.vorp_inventory:isCustomInventoryRegistered(inventoryId)
        if not isRegistered then
            exports.vorp_inventory:registerInventory({
                id = inventoryId,
                name = businessName,
                limit = limit,
                acceptWeapons = false, -- Adjust as needed
                shared = true,
                ignoreItemStackLimit = true,
                whitelistItems = false,
                UsePermissions = false,
                UseBlackList = false,
                whitelistWeapons = false
            })
            inventoriesRegistered[businessId] = inventoryId
        end
    end

    -- Adjust inventory limit based on the upgrade stages
    local finalLimit = limit
    if currentStage ~= 0 then
        local retval = MySQL.query.await("SELECT * FROM bcc_society WHERE business_id = ?", { businessId })
        if #retval > 0 then
            local additionalSlots = 0
            for _, stage in pairs(json.decode(retval[1].inventory_upgrade_stages)) do
                if tonumber(stage.stage) == currentStage then
                    finalLimit = finalLimit + tonumber(stage.slotIncrease)
                elseif tonumber(stage.stage) < currentStage then
                    additionalSlots = additionalSlots + tonumber(stage.slotIncrease)
                end
            end
            finalLimit = finalLimit + additionalSlots
        end
    end
    exports.vorp_inventory:updateCustomInventorySlots(inventoryId, finalLimit)
    Wait(100)
    exports.vorp_inventory:openInventory(_source, inventoryId)
end)

BccUtils.RPC:Register("bcc-society:UpgradeInventory", function(params, cb, recSource)
    local user = Core.getUser(recSource)
    if not user then return cb(false) end

    local char = user.getUsedCharacter
    if not char then return cb(false) end
    local charFullName = char.firstname .. " " .. char.lastname
    if char.money >= tonumber(params.cost) then
        local webhookLink = MySQL.query.await("SELECT * FROM bcc_society WHERE business_id = ?", { params.socId })
        BccUtils.Discord.sendMessage(
            webhookLink.webhook_link,
            Config.WebhookTitle,    -- Set this to your desired title, e.g., "Inventory Upgrade"
            Config.WebhookAvatar,   -- Set this to your desired avatar URL
            _U("inventoryUpgrade"), -- Embed title, e.g., "Inventory Upgrade"
            _U("inventoryUpgradeBy") .. charFullName .. _U("inventoryUpgradedToo") .. params.nextStage
        )
        MySQL.query.await("UPDATE bcc_society SET inventory_current_stage = ? WHERE business_id = ?",
            { tonumber(params.nextStage), params.socId })
        char.removeCurrency(0, tonumber(params.cost))
        return cb(true)
    else
        return cb(false)
    end
end)

BccUtils.RPC:Register("bcc-society:GetInventoryStages", function(params, cb, recSource)
    local retval = MySQL.query.await("SELECT * FROM bcc_society WHERE business_id = ?", { params.socId })
    if #retval > 0 then
        local stagesData = json.decode(retval[1].inventory_upgrade_stages)
        local stageData = nil
        local foundNextStage = false
        if stagesData then
            if #stagesData > 0 then
                for k, v in pairs(stagesData) do
                    if tonumber(v.stage) == tonumber(retval[1].inventory_current_stage) + 1 then
                        foundNextStage = true
                        stageData = { nextStage = v, inventory_current_stage = retval[1].inventory_current_stage }
                        break
                    end
                end
            end
        end
        if not foundNextStage then
            stageData = { nextStage = false, inventory_current_stage = retval[1].inventory_current_stage }
        end
        return cb(stageData)
    else
        return cb(false)
    end
end)
