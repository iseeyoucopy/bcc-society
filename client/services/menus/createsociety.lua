local societyOwnerCharId, societyOwnerSource

function CreateSocietyMenu()
    local societyName, societyTaxAmount, societyInventoryLimit, societyBlipHash, societyJob = "", "", "", "", ""
    BCCSocietyMenu:Close()

    local createSocietyPage = BCCSocietyMenu:RegisterPage("bcc-society:createSocietyPage")
    if not createSocietyPage then return end

    createSocietyPage:RegisterElement("header", {
        value = _U("societyCreationHeader"),
        slot = "header",
        style = {}
    })

    createSocietyPage:RegisterElement("button", {
        label = _U("setSocietyOwner"),
        style = {}
    }, function()
        local playerListPage = GetPlayerListMenuPage(false, function(data)
            societyOwnerCharId = data.charId
            societyOwnerSource = data.source
            Core.NotifyRightTip(_U("ownerSet"), 4000)
            createSocietyPage:RouteTo()
        end, function()
            createSocietyPage:RouteTo()
        end)
        playerListPage:RouteTo()
    end)

    createSocietyPage:RegisterElement("input", {
        label = _U("nameSociety"),
        placeholder = _U("placeholder"),
        style = {}
    }, function(data)
        societyName = data.value
    end)

    createSocietyPage:RegisterElement("input", {
        label = _U("setSocietyJob"),
        placeholder = _U("placeholder"),
        style = {}
    }, function(data)
        societyJob = data.value
    end)

    local maxJobGrade = 5
    createSocietyPage:RegisterElement("input", {
        label = _U("setSocietyMaxJobGrade"),
        placeholder = "0",
        style = {}
    }, function(data)
        maxJobGrade = tonumber(data.value) or 5
    end)

    createSocietyPage:RegisterElement("input", {
        label = _U("societyTaxes"),
        placeholder = _U("placeholder"),
        style = {}
    }, function(data)
        societyTaxAmount = data.value
    end)

    createSocietyPage:RegisterElement("button", {
        label = _U("setSocietyBlipHash"),
        style = {}
    }, function()
        if #Config.blips > 0 then
            local blipPage = BCCSocietyMenu:RegisterPage("bcc-society:blipPage")
            blipPage:RegisterElement("header", {
                value = _U("setSocietyBlipHash"),
                slot = "header",
                style = {}
            })
            for k, v in pairs(Config.blips) do
                blipPage:RegisterElement("button", {
                    label = v.blipName,
                    style = {}
                }, function()
                    societyBlipHash = v.blipHash
                    Core.NotifyRightTip(_U("blipSet"), 4000)
                    createSocietyPage:RouteTo()
                end)
            end

            blipPage:RegisterElement("button", {
                label = _U("back"),
                style = {}
            }, function()
                createSocietyPage:RouteTo()
            end)

            blipPage:RouteTo()
        else
            Core.NotifyRightTip(_U("noBlipsInConfig"), 4000)
        end
    end)

    createSocietyPage:RegisterElement("input", {
        label = _U("baseInventoryLimit"),
        placeholder = _U("placeholder"),
        style = {}
    }, function(data)
        societyInventoryLimit = data.value
    end)

    local stages = {}
    createSocietyPage:RegisterElement("button", {
        label = _U("inventoryStage"),
        style = {}
    }, function()
        local upgradeStagesPage = BCCSocietyMenu:RegisterPage("bcc-society:upgradeStagesPage")
        upgradeStagesPage:RegisterElement("header", {
            value = _U("inventoryStage"),
            slot = "header",
            style = {}
        })

        local stage, stageCost, stageSlotIncrease = "", "", ""
        upgradeStagesPage:RegisterElement("input", {
            label = _U("inventoryUpgradeStages"),
            placeholder = _U("placeholder"),
            style = {}
        }, function(data)
            stage = data.value
        end)

        upgradeStagesPage:RegisterElement("input", {
            label = _U("inventoryStageCost"),
            placeholder = _U("placeholder"),
            style = {}
        }, function(data)
            stageCost = data.value
        end)

        upgradeStagesPage:RegisterElement("input", {
            label = _U("inventoryStageSlotIncrease"),
            placeholder = _U("placeholder"),
            style = {}
        }, function(data)
            stageSlotIncrease = data.value
        end)

        upgradeStagesPage:RegisterElement("button", {
            label = _U("confirm"),
            style = {}
        }, function()
            if stage ~= "" and stageCost ~= "" and stageSlotIncrease ~= "" and tonumber(stageCost) and tonumber(stage) and tonumber(stageSlotIncrease) then
                local insert = true
                for k, v in pairs(stages) do
                    if tonumber(v.stage) == tonumber(stage) then
                        insert = false
                        Core.NotifyRightTip(_U("inventoryStageExists"), 4000)
                        break
                    end
                end
                if insert then
                    stages[tonumber(stage)] = { stage = stage, cost = tonumber(stageCost), slotIncrease = tonumber(stageSlotIncrease) }
                    Core.NotifyRightTip(_U("stageCreated"), 4000)
                end
            end
        end)

        upgradeStagesPage:RegisterElement("line", {
            slot = "footer",
            style = {}
        })

        upgradeStagesPage:RegisterElement("button", {
            label = _U("back"),
            slot = "footer",
            style = {}
        }, function()
            createSocietyPage:RouteTo()
        end)

        upgradeStagesPage:RegisterElement("bottomline", {
            slot = "footer",
            style = {}
        })

        upgradeStagesPage:RouteTo()
    end)

    createSocietyPage:RegisterElement("line", {
        slot = "footer",
        style = {}
    })

    createSocietyPage:RegisterElement("button", {
        label = _U("confirm"),
        slot = "footer",
        style = {}
    }, function()
        -- Set default values if not already set
        if societyBlipHash == "" then societyBlipHash = "blip_shop_store" end
        if not tonumber(maxJobGrade) or maxJobGrade == nil or maxJobGrade <= 0 then maxJobGrade = 5 end
    
        -- Check if all necessary fields are filled
        if societyName ~= "" and societyOwnerCharId ~= nil and societyOwnerSource ~= nil 
           and societyTaxAmount ~= "" and societyInventoryLimit ~= "" then
           
            -- Trigger the server event with the appropriate parameters
            if #stages > 0 then
                TriggerServerEvent('bcc-society:InsertSocietyToDB', societyName, societyOwnerCharId, 
                    societyOwnerSource, societyTaxAmount, societyInventoryLimit, 
                    GetEntityCoords(PlayerPedId()), societyBlipHash, json.encode(stages), 
                    societyJob, maxJobGrade)
            else
                TriggerServerEvent('bcc-society:InsertSocietyToDB', societyName, societyOwnerCharId, 
                    societyOwnerSource, societyTaxAmount, societyInventoryLimit, 
                    GetEntityCoords(PlayerPedId()), societyBlipHash, "none", 
                    societyJob, maxJobGrade)
            end
            
            BCCSocietyMenu:Close()
        else
            Core.NotifyRightTip(_U("fillAllFields"), 4000)
        end
    end)
    
    createSocietyPage:RegisterElement("bottomline", {
        slot = "footer",
        style = {}
    })

    BCCSocietyMenu:Open({
        startupPage = createSocietyPage
    })
end

RegisterCommand(Config.createSocietyCommandName, function()
    if IsAdmin then
        CreateSocietyMenu()
    end
end)
