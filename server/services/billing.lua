BccUtils.RPC:Register("bcc-society:BillPlayer", function(params, cb, src)
    local _source = src
    local playerServerId = params.playerServerId
    local amount = params.amount
    local description = params.description

    devPrint("Billing started by source: " .. tostring(_source) .. " for target: " .. tostring(playerServerId) .. " amount: " .. tostring(amount))

    -- Get source character
    local billerUser = Core.getUser(_source)
    if not billerUser then
        devPrint("No user session for source: " .. tostring(_source))
        return
    end
    local biller = billerUser.getUsedCharacter
    if not biller then
        devPrint("No character loaded for source: " .. tostring(_source))
        return
    end

    -- Get target character
    local billedUser = Core.getUser(playerServerId)
    if not billedUser then
        devPrint("No user session for billed: " .. tostring(playerServerId))
        return
    end
    local billed = billedUser.getUsedCharacter
    if not billed then
        devPrint("No character loaded for billed: " .. tostring(playerServerId))
        return
    end

    local cost = tonumber(amount)
    if not cost or cost <= 0 then
        devPrint("Invalid cost entered: " .. tostring(amount))
        Core.NotifyRightTip(_source, _U("invalidAmount"), 4000)
        return
    end

    if billed.money < cost then
        devPrint("Insufficient funds. Has: " .. billed.money .. ", needs: " .. cost)
        Core.NotifyRightTip(_source, _U("targetNoMoney"), 4000)
        return
    end

    -- Deduct and handle transfer
    devPrint("Deducting $" .. cost .. " from billed.")
    billed.removeCurrency(0, cost)

    local society = params.societyId and SocietyAPI:GetSociety(params.societyId)
    if society then
        devPrint("Found society: " .. tostring(society.id) .. " - Adding to ledger.")
        society:AddMoneyToLedger(cost)
    else
        devPrint("No society found. Adding to biller’s wallet.")
        biller.addCurrency(0, cost)
    end

    -- Create DB record
    local timestamp = os.time()
    devPrint("Inserting DB bill at timestamp: " .. tostring(timestamp))

    local insertId = MySQL.insert.await(
        'INSERT INTO bcc_society_bills (billed_identifier, biller_identifier, billed_name, biller_name, amount, society_id, description, timestamp, status) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
        {
            billed.identifier,
            biller.identifier,
            billed.firstname .. " " .. billed.lastname,
            biller.firstname .. " " .. biller.lastname,
            cost,
            society and society.id,
            description,
            timestamp,
            "PAID"
        })
    devPrint("Giving receipt to billed player: " .. billed.identifier)

    -- Add the item with metadata right away
    exports.vorp_inventory:addItem(playerServerId, Config.bill_receiptitem, 1, {
        description = "Receipt from billing",
        receipt_id = insertId
    })
    
    devPrint("Added ".. Config.bill_receiptitem.. " with metadata receipt_id: " .. tostring(insertId))


    -- Notify
    devPrint("Sending UI notifications.")
    Core.NotifyRightTip(playerServerId, _U("youHaveBeenBilled") .. cost .. _U("checkInvnt"), 5000)
    Core.NotifyRightTip(_source, _U("billSuccess"), 4000)

    -- Discord log
    devPrint("Sending to Discord log.")
    BccUtils.Discord.sendMessage(
        Config.adminLogsWebhook,
        Config.WebhookTitle,
        Config.WebhookAvatar,
        _U("playerBilled"),
        _U("playerBilled") .. cost
    )
end)

local function GetReceiptById(receiptId)
    if not receiptId then
        devPrint("[GetReceiptById] No receipt ID provided.")
        return nil
    end

    local result = MySQL.query.await([[
        SELECT b.*, s.business_name
        FROM bcc_society_bills b
        LEFT JOIN bcc_society s ON b.society_id = s.business_id
        WHERE b.id = ?
    ]], { tonumber(receiptId) })

    if result and #result > 0 then
        local bill = result[1]
        devPrint("[GetReceiptById] Found receipt: " .. json.encode(bill))
        return {
            id = bill.id,
            amount = bill.amount,
            paidFrom = bill.biller_name,
            paidTo = bill.billed_name,
            society = bill.business_name,
            timestamp = os.date("%Y-%m-%d %H:%M:%S", bill.timestamp),
            description = bill.description,
            status = bill.status
        }
    else
        devPrint("[GetReceiptById] No receipt found for ID: " .. tostring(receiptId))
        return nil
    end
end

BccUtils.RPC:Register("bcc-society:OpenReceiptMenu", function(receiptId, src)
    if not receiptId then return end

    local result = MySQL.query.await("SELECT * FROM bcc_society_bills WHERE id = ?", { receiptId })
    if result and result[1] then
        OpenReceiptMenu(result[1])
    else
        Core.NotifyRightTip(src, _U("receiptNotFound"), 4000)
    end
end)

BccUtils.RPC:Register("bcc-society:RevokeReceipt", function(params, cb, src)
    local receiptId = params and params.receiptId
    devPrint("[RevokeReceipt] Requested by src: " .. tostring(src) .. ", receiptId: " .. tostring(receiptId))

    if not receiptId then
        devPrint("[RevokeReceipt] Missing receiptId.")
        return cb(false)
    end

    local user = Core.getUser(src)
    if not user then 
        devPrint("[RevokeReceipt] User not found for source: " .. tostring(src))
        return cb(false)
    end

    local character = user.getUsedCharacter
    if not character then 
        devPrint("[RevokeReceipt] Character not found for source: " .. tostring(src))
        return cb(false)
    end

    local identifier = character.identifier
    devPrint("[RevokeReceipt] Character identifier: " .. tostring(identifier))

    MySQL.query('SELECT * FROM bcc_society_bills WHERE id = ? AND billed_identifier = ?', {receiptId, identifier}, function(result)
        if result and result[1] then
            local bill = result[1]
            devPrint("[RevokeReceipt] Receipt found with status: " .. tostring(bill.status))

            if bill.status == "PAID" then
                MySQL.execute('DELETE FROM bcc_society_bills WHERE id = ?', {receiptId}, function()
                    devPrint("[RevokeReceipt] Receipt deleted from DB. Removing item...")
                    exports.vorp_inventory:subItem(src, Config.bill_receiptitem, 1)
                    cb(true)
                end)
            else
                devPrint("[RevokeReceipt] Receipt exists but is not marked as PAID.")
                cb(false)
            end
        else
            devPrint("[RevokeReceipt] Receipt not found or doesn't belong to this character.")
            cb(false)
        end
    end)
end)

local function HandleReceiptItemUse(data)
    local src = data.source
    exports.vorp_inventory:closeInventory(src)

    if not data.item or type(data.item.metadata) ~= "table" then
        Core.NotifyRightTip(src, _U("invalidReceiptItem"), 4000)

        -- Delete the item if metadata is missing or invalid
        if data.item and data.item.id then
            devPrint("[HandleReceiptItemUse] Removing invalid item ID: " .. tostring(data.item.id))
            exports.vorp_inventory:subItemID(src, data.item.id)
        end
        return
    end

    local metadata = data.item.metadata
    local receiptId = metadata.receipt_id

    if not receiptId then
        Core.NotifyRightTip(src, _U("receiptNotFoundAndDeleted"), 4000)
        Wait(2000)
        -- Delete the item if it doesn't contain a valid receipt_id
        if data.item and data.item.id then
            devPrint("[HandleReceiptItemUse] Removing item with no receipt_id. ID: " .. tostring(data.item.id))
            exports.vorp_inventory:subItemID(src, data.item.id)
        end
        return
    end

    local receipt = GetReceiptById(receiptId)
    if receipt then
        receipt._target = src
        BccUtils.RPC:Notify("bcc-society:OpenReceiptMenu", receipt, src)
    else
        Core.NotifyRightTip(src, _U("receiptNotFound"), 4000)
    end
end

exports.vorp_inventory:registerUsableItem(Config.bill_receiptitem, HandleReceiptItemUse, GetCurrentResourceName())
