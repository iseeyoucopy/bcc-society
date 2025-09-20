-- Main page of client
AdminAllowed = nil
local blips = {}
local OwnedSocieties = {} -- key = business_id, value = true

function IsSocietyOwner(businessId)
    return OwnedSocieties[businessId] == true
end

CreateThread(function() -- Devmode area
    if Config.devMode then
        AdminAllowed = BccUtils.RPC:CallAsync("BCC-Society:AdminCheck")
        devPrint("[RPC] Admin check result: " .. tostring(AdminAllowed))
        TriggerServerEvent("bcc-society:CheckIfInSociety")
    end
end)

RegisterNetEvent('vorp:SelectedCharacter')
AddEventHandler('vorp:SelectedCharacter', function()
    AdminAllowed = BccUtils.RPC:CallAsync("BCC-Society:AdminCheck")
    devPrint("[RPC] Admin check result: " .. tostring(AdminAllowed))
    TriggerServerEvent("bcc-society:CheckIfInSociety")
end)

RegisterNetEvent("bcc-society:ReceiveSocietyData", function(result)
    if result then
        for _, v in ipairs(result.societiesOwned) do
            OwnedSocieties[v.business_id] = true
            devPrint("[ReceiveSocietyData] Registered owner of:" .. v.business_name .. " (ID: " .. v.business_id .. ")")
            TriggerEvent("bcc-society:SocietyStart", true, v)
        end

        for _, v in ipairs(result.societiesEmployed) do
            devPrint("[ReceiveSocietyData] Registered employee at:" .. v.business_name .. " (ID: " .. v.business_id .. ")")
            TriggerEvent("bcc-society:SocietyStart", false, v)
        end
    end
end)

RegisterNetEvent("bcc-society:SocietyStart", function(isOwner, societyData)
    devPrint("[SocietyStart] Triggered for society:" .. societyData.business_name .. "| IsOwner:" .. tostring(isOwner))

    local isOwner = IsSocietyOwner(societyData.business_id)
    RegisterCommand(Config.billCommandName, function()
        devPrint("[BillingCommand] Executed command:" .. Config.billCommandName)
    
        if isOwner then
            devPrint("[BillingCommand] Confirmed as owner for society:" .. societyData.business_name)
            OpenBillingMenu(societyData)
            return
        end
    
        BccUtils.RPC:Call("bcc-society:GetEmployeeData", {
            socId = societyData.business_id,
            recType = "rankData"
        }, function(billData)
            if billData then
                devPrint("[BillingCommand] Received employee billData:" .. json.encode(billData))
                if billData.rank_can_bill_players == "true" then
                    devPrint("[BillingCommand] Employee rank allows billing.")
                    OpenBillingMenu(societyData)
                else
                    devPrint("[BillingCommand] Employee rank does NOT allow billing.")
                    Notify(_U("noBillPerms"), "error", 4000)
                end
            else
                devPrint("[BillingCommand] No employee rank data found.")
                Notify("No rank data found or you're not onduty", "error", 4000)
            end
        end)
    end)
          
    
    -- Fired and payment handling
    local isFired = false
    RegisterNetEvent('bcc-society:FiredFrom:' .. societyData.business_id, function()
        isFired = true
        TriggerEvent("bcc-society:FiredFrom" .. societyData.business_id .. "StopPay")
    end)

    if isOwner or not isOwner then
        TriggerEvent("bcc-society:StartPayTimer", societyData.business_id)
    end

    -- Blip setup
    local societyCoords = json.decode(societyData.coords)
    local societyCoordsVector3 = vector3(societyCoords.x, societyCoords.y, societyCoords.z)
    if societyData.show_blip == "true" and Config.allowBlips and societyData.blip_hash ~= "none" then
        TriggerServerEvent("bcc-society:ServerSyncBlips", societyData.business_name, societyData.blip_hash, societyCoordsVector3, societyData.business_id, false)
    end

    -- Prompt setup
    local promptGroup = BccUtils.Prompt:SetupPromptGroup()
    local firstPrompt = promptGroup:RegisterPrompt(_U("manage"), Config.manageSocietyPromptKey, 1, 1, true, 'hold',
        { timedeventhash = 'MEDIUM_TIMED_EVENT' })

    while true do
        local playerCoords = GetEntityCoords(PlayerPedId())
        local dist = #(societyCoordsVector3 - playerCoords)

        if isFired then break end

        if dist < 50 then
            if dist < Config.openMenuRadius then
                promptGroup:ShowGroup(societyData.business_name)
                if firstPrompt:HasCompleted() then
                    ManageSocietyMenu(societyData, societyCoordsVector3, isOwner)
                end
            end
        else
            Wait(1000)
        end
        Wait(5)
    end
end)

AddEventHandler("bcc-society:StartPayTimer", function(businessId)
    local fired = false
    AddEventHandler("bcc-society:FiredFrom:" .. businessId .. "StopPay", function()
        fired = true
    end)

    while true do
        if fired then break end
        local rankData = BccUtils.RPC:CallAsync("bcc-society:GetEmployeeData", { socId = businessId, recType = "rankData" })

        if rankData then
            local rankPay = tonumber(rankData.rank_pay)
            local rankPayIncrement = tonumber(rankData.rank_pay_increment)
            if rankPay and rankPayIncrement then
                Wait(rankPayIncrement * 60000)
                TriggerServerEvent('bcc-society:PayEmployee', rankPay, businessId)
            else
                Wait(1000)
            end
        else
            Wait(1000)
        end
    end
end)

RegisterNetEvent('bcc-society:ClientSyncBlips', function(blipName, blipHash, blipVector3, blipSocietyId, delete)
    if not delete then
        local blip = BccUtils.Blips:SetBlip(blipName, blipHash, 0.2, nil, nil, nil, blipVector3)
        table.insert(blips, { societyBlip = blip, blipSocietyId = blipSocietyId }) --So we can make sure to remove it on all clients and enable it on all clients
    else
        for k, v in pairs(blips) do
            if v.blipSocietyId == blipSocietyId then
                v.societyBlip:Remove()

                table.remove(blips, k)
                break
            end
        end
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        if #blips then
            for k, v in pairs(blips) do
                v.societyBlip:Remove()
            end
        end
        BCCSocietyMenu:Close()
        TriggerServerEvent('bcc-society:ToggleOffDuty')
    end
end)
