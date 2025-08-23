BccUtils.RPC:Register("bcc-society:GetLedgerData", function(params, cb, recSource)
    local ledgerData = SocietyAPI:GetSociety(params.socId):GetLedgerAmount()
    if ledgerData then
        return cb(ledgerData)
    else
        return cb(false)
    end
end)

RegisterServerEvent("bcc-society:LedgerManagement", function(businessId, amount, type)
    local _source = source
    local user = Core.getUser(_source)
    if not user then return end
    
    local character = user.getUsedCharacter
    if not character then return end

    local society = SocietyAPI:GetSociety(businessId)
    if society then
        local socData = society:GetSocietyInfo()
        if socData then
            local ledgerAmount = tonumber(socData.ledger)
            local amountToProcess = tonumber(amount)

            if not amountToProcess then
                NotifyClient(_source, _U("invalidAmount"), "error", 4000)
                return
            end

            if type == "deposit" then
                if character.money and character.money >= amountToProcess then
                    society:AddMoneyToLedger(amountToProcess)
                    character.removeCurrency(0, amountToProcess)
                    NotifyClient(_source, _U("depositSuccess"), "success", 4000)
                else
                    NotifyClient(_source, _U("notEnoughCash"), "error", 4000)
                end
            elseif type == "withdraw" then
                if ledgerAmount >= amountToProcess then
                    society:RemoveMoneyFromLedger(amountToProcess)
                    character.addCurrency(0, amountToProcess)
                    NotifyClient(_source, _U("withdrawSuccess"), "success", 4000)
                else
                    NotifyClient(_source, _U("notEnoughFundsInLedger"), "error", 4000)
                end
            else
                NotifyClient(_source, _U("invalidTransactionType"), "error", 4000)
            end
        end
    end
end)

