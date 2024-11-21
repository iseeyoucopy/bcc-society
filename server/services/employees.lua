BccUtils.RPC:Register("bcc-society:GetAllEmployeesData", function(params, cb, recSource)
    local employees = SocietyAPI:GetSociety(params.socId):GetSocietyEmployees()
    if employees and type(employees) == "table" and #employees > 0 then
        local employeesCharIds = {}
        for k, v in pairs(employees) do
            table.insert(employeesCharIds, {charId = v.employee_id, employeeName = v.employee_name, employeeRank = v.employee_rank})
        end
        if params.recType ~= "viewEmployees" then
            local ownerId = SocietyAPI:GetSociety(params.socId):GetSocietyOwnerCharacterId()
            if ownerId then
                table.insert(employeesCharIds, {charId = ownerId})
            end
        end
        return cb(employeesCharIds)
    else
        local employeesCharIds = {}
        if params.recType ~= 'viewEmployees' then
            local ownerId = SocietyAPI:GetSociety(params.socId):GetSocietyOwnerCharacterId()
            if ownerId then
                table.insert(employeesCharIds, {charId = ownerId})
                return cb(employeesCharIds)
            else
                return cb(false)
            end
        else
            return cb(false)
        end
    end
end)

RegisterServerEvent('bcc-society:PlayerHired', function(businessId, playerCharId, playerSource, societyData)
    local _source = source
    local employeeUser = Core.getUser(playerSource)
    local hiringUser = Core.getUser(_source)

    if not employeeUser or not hiringUser then return end
    local employeeChar = employeeUser.getUsedCharacter
    local hiringChar = hiringUser.getUsedCharacter
    if not employeeChar or not hiringChar then return end

    local employeeFullName = (employeeChar.firstname or "Unknown") .. " " .. (employeeChar.lastname or "Unknown")
    local hiringFullName = (hiringChar.firstname or "Unknown") .. " " .. (hiringChar.lastname or "Unknown")

    if not Config.employeeWorksAtMultiple then
        local employee = MySQL.query.await("SELECT * FROM bcc_society_employees WHERE employee_id = ? AND business_id = ?", { playerCharId, businessId })
        local owner = MySQL.query.await("SELECT * FROM bcc_society WHERE owner_id = ?", { playerCharId })
        
        if #employee > 0 or #owner > 0 then
            Core.NotifyRightTip(_source, _U("playerCanNotBeHired"), 4000)
        else
            -- Retrieve rank information from bcc_society_ranks table
            local rankInfo = MySQL.query.await("SELECT rank_name, society_job_rank FROM bcc_society_ranks WHERE business_id = ? ORDER BY society_job_rank ASC LIMIT 1", { businessId })
            
            if rankInfo and #rankInfo > 0 then
                -- Insert new employee and set job and grade based on rank
                MySQL.query.await("INSERT INTO bcc_society_employees (employee_id, business_id, employee_name, employee_rank) VALUES (?, ?, ?, ?)", { playerCharId, businessId, employeeFullName, rankInfo[1].rank_name })
                
                employeeChar.setJob(rankInfo[1].rank_name, true)  -- Set job to rank_name
                employeeChar.setJobGrade(rankInfo[1].society_job_rank, true)  -- Set job grade to society_job_rank
                
                Core.NotifyRightTip(_source, _U("employeeHired"), 4000)
                BccUtils.Discord.sendMessage(
                    societyData.webhook_link, Config.WebhookTitle, Config.WebhookAvatar, 
                    _U("employeeHired"), 
                    "**" .. _U("employeeHiredBy") .. "** " .. hiringFullName .. "\n" ..
                    "**Employee Name:** " .. employeeFullName .. "\n" ..
                    "**Business Name:** " .. societyData.business_name
                )
                BccUtils.Discord.sendMessage(
                    Config.adminLogsWebhook, Config.WebhookTitle, Config.WebhookAvatar, 
                    _U("employeeHired"), 
                    "**" .. _U("employeeHiredBy") .. "** " .. hiringFullName .. "\n" ..
                    "**Employee Name:** " .. employeeFullName .. "\n" ..
                    "**Business Name:** " .. societyData.business_name
                )
                Core.NotifyRightTip(playerSource, _U("youWereHired") .. societyData.business_name, 4000)
                TriggerClientEvent("bcc-society:SocietyStart", playerSource, false, societyData)
            else
                Core.NotifyRightTip(_source, _U("rankNotFound"), 4000)
            end
        end
    else
        local rankInfo = MySQL.query.await("SELECT rank_name, society_job_rank FROM bcc_society_ranks WHERE business_id = ? ORDER BY society_job_rank ASC LIMIT 1", { businessId })
        
        if rankInfo and #rankInfo > 0 then
            -- Insert employee record with "off" prefixed rank name in the database
            local offRankName = "off" .. rankInfo[1].rank_name
            MySQL.query.await("INSERT INTO bcc_society_employees (employee_id, business_id, employee_name, employee_rank) VALUES (?, ?, ?, ?)", { playerCharId, businessId, employeeFullName, offRankName })

            -- Set the job for the employee with the "off" prefixed rank name
            employeeChar.setJob(offRankName, true)
            employeeChar.setJobGrade(rankInfo[1].society_job_rank, true)
            Core.NotifyRightTip(_source, _U("employeeHired"), 4000)
            BccUtils.Discord.sendMessage(
                societyData.webhook_link, Config.WebhookTitle, Config.WebhookAvatar, 
                _U("employeeHired"), 
                "**" .. _U("employeeHiredBy") .. "** " .. hiringFullName .. "\n" ..
                "**Employee Name:** " .. employeeFullName .. "\n" ..
                "**Business Name:** " .. societyData.business_name
            )
            BccUtils.Discord.sendMessage(
                Config.adminLogsWebhook, Config.WebhookTitle, Config.WebhookAvatar, 
                _U("employeeHired"), 
                "**" .. _U("employeeHiredBy") .. "** " .. hiringFullName .. "\n" ..
                "**Employee Name:** " .. employeeFullName .. "\n" ..
                "**Business Name:** " .. societyData.business_name
            )
            Core.NotifyRightTip(playerSource, _U("youWereHired") .. societyData.business_name, 4000)
            TriggerClientEvent("bcc-society:SocietyStart", playerSource, false, societyData)
        else
            Core.NotifyRightTip(_source, _U("noRanks"), 4000)
        end
    end
end)

RegisterServerEvent('bcc-society:FireEmployee', function(businessId, playerCharId, societyData)
    local _source = source

    local allPlayers = GetPlayers()

    for _, playerId in ipairs(allPlayers) do
        local char = Core.getUser(playerId)
        if char and char.getUsedCharacter and char.getUsedCharacter.charIdentifier == playerCharId then
            -- Set the job to "unemployed" with grade 0
            char.getUsedCharacter.setJob("unemployed", true)
            char.getUsedCharacter.setJobGrade(0, true)

            Core.NotifyRightTip(playerId, _U("youWereFired") .. societyData.business_name, 4000)
            TriggerClientEvent('bcc-society:FiredFrom:' .. businessId, playerId)
            break
        end
    end

    local fireuserChar = Core.getUser(_source)
    local fireChar = fireuserChar.getUsedCharacter
    local charFullName = fireChar.firstname .. " " .. fireChar.lastname
    BccUtils.Discord.sendMessage(
        societyData.webhook_link, Config.WebhookTitle, Config.WebhookAvatar, 
        _U("employeeFired"), 
        "**Fired By:** " .. charFullName .. "\n" ..
        "**Business Name:** " .. societyData.business_name
    )
    MySQL.query.await("DELETE FROM bcc_society_employees WHERE employee_id = ? AND business_id = ?", { playerCharId, businessId })
    Core.NotifyRightTip(_source, _U("employeeFired"), 4000)
end)

RegisterServerEvent('bcc-society:ChangeEmployeeRank', function(businessId, rankName, employeeId, businessName)
    local _source = source
    local retval = MySQL.query.await("SELECT * FROM bcc_society_employees WHERE business_id = ? AND employee_id = ?", { businessId, employeeId })
    
    if #retval > 0 then
        -- Retrieve the rank data to get society_job_rank associated with rankName
        local rankData = MySQL.query.await("SELECT society_job_rank FROM bcc_society_ranks WHERE business_id = ? AND rank_name = ?", { businessId, rankName })
        
        if rankData and #rankData > 0 then
            local newJobGrade = rankData[1].society_job_rank
            
            -- Update the employee's rank in the database
            MySQL.query.await("UPDATE bcc_society_employees SET employee_rank = ? WHERE business_id = ? AND employee_id = ?", { rankName, businessId, employeeId })
            
            -- Fetch all online players
            local allPlayers = GetPlayers()

            for _, playerId in ipairs(allPlayers) do
                local char = Core.getUser(playerId)
                if char and char.getUsedCharacter and char.getUsedCharacter.charIdentifier == employeeId then
                    char.getUsedCharacter.setJob(rankName, true)        -- Set job to new rank name
                    char.getUsedCharacter.setJobGrade(newJobGrade, true) -- Set job grade to new society_job_rank

                    Core.NotifyRightTip(playerId, _U("yourRankWasChanged") .. rankName .. " " .. _U("yourRankWasChangedAt") .. businessName, 4000)
                    TriggerClientEvent('bcc-society:UpdateEmployeeData:' .. businessId, playerId)
                    break
                end
            end


            Core.NotifyRightTip(_source, _U("employeeRankChanged"), 4000)

            -- Send Discord message
            BccUtils.Discord.sendMessage(
                Config.adminLogsWebhook, Config.WebhookTitle, Config.WebhookAvatar, 
                _U("employeeRankChanged"), 
                "**Employee Name:** " .. retval[1].employee_name .. "\n" ..
                "**New Rank:** " .. rankName .. "\n" ..
                "**New Job Grade:** " .. tostring(newJobGrade) .. "\n" ..
                "**Business Name:** " .. businessName
            )
        else
            Core.NotifyRightTip(_source, _U("rankNotFound"), 4000)
        end
    end
end)


BccUtils.RPC:Register("bcc-society:GetEmployeeData", function(params, cb, recSource)
    local user = Core.getUser(recSource)
    
    if not user then return cb(false) end
    
    local char = user.getUsedCharacter
    if not char then return cb(false) end

    local charId = char.charIdentifier
    local society = SocietyAPI:GetSociety(params.socId)

    if society then
        local employeeData = society:GetEmployeeData(charId)

        if params.recType == "employeeData" then
            cb(employeeData)
        elseif params.recType == "rankData" then
            if employeeData then
                local employeeRankName = society:GetEmployeeRank(charId)
                if employeeRankName then
                    cb(society:GetRankInfo(employeeRankName))
                else
                    cb(false)
                end
            else
                cb(false)
            end
        end
    else
        cb(false)
    end
end)

BccUtils.RPC:Register("bcc-society:GetPaymentAmount", function(params, cb, recSource)
    local user = Core.getUser(recSource)
    if not user then return cb(false) end

    local char = user.getUsedCharacter
    if not char then return cb(false) end

    -- Fetch payment amount from the `bcc_society_employees` table
    local employeeData = MySQL.query.await("SELECT employee_payment FROM bcc_society_employees WHERE employee_id = ?", { char.charIdentifier })

    if employeeData and #employeeData > 0 then
        local paymentAmount = tonumber(employeeData[1].employee_payment)
        if paymentAmount and paymentAmount > 0 then
            cb(paymentAmount) -- Return the payment amount to the client
        else
            cb(false) -- Return false if payment amount is 0
        end
    else
        cb(false) -- Return false if data is not found
        Core.NotifyRightTip(recSource, _U('unableToRetrieve'), 4000)
    end
end)

-- Define a cooldown table to store the last collection time for each player
local playerPaymentCooldowns = {}

RegisterServerEvent("bcc-society:CollectPayment", function()
    local _source = source
    local user = Core.getUser(_source)
    if not user then return end
    local char = user.getUsedCharacter
    local charFullName = char.firstname .. " " .. char.lastname

    -- Cooldown check: allow payment collection only if the cooldown period has passed
    local currentTime = os.time()
    local cooldownTime = 120 -- Cooldown time in seconds (e.g., 2 minutes)
    if playerPaymentCooldowns[_source] and currentTime - playerPaymentCooldowns[_source] < cooldownTime then
        Core.NotifyRightTip(_source, _U('cooldownActive'), 4000)
        return
    end

    local employeeData = MySQL.query.await("SELECT e.employee_payment, s.ledger, s.webhook_link, s.business_id FROM bcc_society_employees e JOIN bcc_society s ON e.business_id = s.business_id WHERE e.employee_id = ?", { char.charIdentifier })
    if employeeData and #employeeData > 0 then
        local payAmount = tonumber(employeeData[1].employee_payment)
        local ledgerAmount = tonumber(employeeData[1].ledger)
        local societyId = employeeData[1].business_id
        if payAmount and payAmount > 0 then
            if ledgerAmount >= payAmount then
                -- Complete payment and update ledger
                char.addCurrency(0, payAmount)
                local ledgerUpdate = MySQL.query.await("UPDATE bcc_society SET ledger = ledger - ? WHERE business_id = ?", { payAmount, societyId })
                -- Confirm the updated ledger amount
                local updatedLedgerData = MySQL.query.await("SELECT ledger FROM bcc_society WHERE business_id = ?", { societyId })
                
                MySQL.query.await("UPDATE bcc_society_employees SET employee_payment = 0 WHERE employee_id = ? AND business_id = ?", { char.charIdentifier, societyId })

                Core.NotifyRightTip(_source, _U('youHaveCollected') .. tostring(payAmount), 4000)
                
                -- Discord notification
                local paymentMessage = "**Payment Collected**\n" ..
                                       "**Employee:** " .. charFullName .. "\n" ..
                                       "**Amount Paid:** $" .. tostring(payAmount) .. "\n" ..
                                       "**Remaining Ledger:** $" .. tostring(updatedLedgerData[1].ledger)
                
                BccUtils.Discord.sendMessage(employeeData[1].webhook_link, Config.WebhookTitle, Config.WebhookAvatar, "Payment Collected", paymentMessage)

                -- Set the last collection time for the player to the current time
                playerPaymentCooldowns[_source] = currentTime
            else
                Core.NotifyRightTip(_source, _U('insufficientFunds'), 4000)
            end
        else
            Core.NotifyRightTip(_source, _U('youCannotCollect'), 4000)
        end
    else
        Core.NotifyRightTip(_source, _U('youNeedToBeOnDuty'), 4000)
    end
end)

RegisterServerEvent("bcc-society:PayEmployee", function(payAmount, societyId)
    local _source = source
    local user = Core.getUser(_source)
    if not user then return end
    local char = user.getUsedCharacter

    -- Fetch the current employee payment amount directly
    local employeeData = MySQL.query.await("SELECT employee_payment FROM bcc_society_employees WHERE employee_id = ? AND business_id = ?", { char.charIdentifier, societyId })
    if employeeData and #employeeData > 0 then
        local currentPayAmount = tonumber(employeeData[1].employee_payment)
        local newPayAmount = currentPayAmount + payAmount

            MySQL.update.await("UPDATE bcc_society_employees SET employee_payment = ? WHERE employee_id = ? AND business_id = ?", { newPayAmount, char.charIdentifier, societyId })
    else
        Core.NotifyRightTip(_source, _U('youNeedToBeOnDuty'), 4000)
    end
end)
