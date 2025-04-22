BccUtils.RPC:Register("bcc-society:OpenReceiptMenu", function(params)
    local myServerId = GetPlayerServerId(PlayerId())
    if params and params._target and params._target ~= myServerId then
        return -- Ignore if not meant for this player
    end

    devPrint("[Client] Opening receipt menu with:" .. json.encode(params))
    OpenReceiptMenu(params)
end)

function OpenReceiptMenu(receipt)
    local receiptPage = BCCSocietyMenu:RegisterPage("bcc-society:receiptPage")

    receiptPage:RegisterElement("header", {
        value = "📜 " .. _U("billReceipt"),
        slot = "header",
        style = {}
    })

    -- Clean formatting
    local amount = receipt.amount
    local from = receipt.paidFrom
    local to = receipt.paidTo
    local date = receipt.timestamp and ("" .. receipt.timestamp)
    local society = receipt.society
    local description = receipt.description
    local status = receipt.status

    local receiptHtml = [[
        <div style="padding: 50px; color: #e2c8a0; width: 100%; margin: 0 auto; box-shadow: 0 0 15px rgba(255,255,255,0.1); font-family: 'Courier New', monospace; background-color: rgba(0, 0, 0, 0.4); border-radius: 8px;">
            <hr style="border: 1px dashed #d4b890;">

            <p><strong style="color:#ffd59a;">]] .. _U("receiptFrom") .. [[</strong> <span style="color:#f3e0c7;">]] .. from .. [[</span></p>
            <p><strong style="color:#ffd59a;">]] .. _U("receiptTo") .. [[</strong> <span style="color:#f3e0c7;">]] .. to .. [[</span></p>
            <p><strong style="color:#f4b26d;">]] .. _U("receiptAmount") .. [[</strong> <span style="color:#ffffff;">$]] .. amount .. [[</span></p>
            <p><strong style="color:#f4b26d;">]] .. _U("receiptSociety") .. [[</strong> <span style="color:#ffffff;">]] .. society .. [[</span></p>
            <p><strong style="color:#efad74;">]] .. _U("receiptDate") .. [[</strong> <span style="color:#f3e0c7;">]] .. date .. [[</span></p>
            <p><strong style="color:#efad74;">]] .. _U("receiptDescription") .. [[</strong> <span style="color:#f3e0c7;">]] .. description .. [[</span></p>
            <p><strong style="color:#e3a861;">]] .. _U("receiptStatus") .. [[</strong> <span style="color: ]] .. (status == "PAID" and "#75ff90" or "#ff6e6e") .. [[;">]] .. status .. [[</span></p>
    
            <hr style="border: 1px dashed #d4b890;">
            <p style="text-align:center; font-size: 12px; color: #d4b890;">]] .. _U("receiptThankYou") .. [[</p>
        </div>
    ]]
    

    receiptPage:RegisterElement("html", {
        slot = "content",
        value = { receiptHtml }
    })

    receiptPage:RegisterElement("line", {
        slot = "footer",
        style = {}
    })

    receiptPage:RegisterElement("button", {
        label = _U("deleteReceipt"),
        slot = "footer",
        style = {}
    }, function()
        if receipt and receipt.id then
            BccUtils.RPC:Call("bcc-society:RevokeReceipt", {
                receiptId = receipt.id
            }, function(success, msg)
                if success then
                    Core.NotifyRightTip(_U("receiptDeleted"), 4000)
                    BCCSocietyMenu:Close()
                else
                    Core.NotifyRightTip(_U(msg) or _U("receiptDeleteFailed"), 4000)
                end
            end)
        else
            devPrint("[Client] Invalid receipt or missing ID for deletion.")
            Core.NotifyRightTip(_U("invalidReceipt"), 4000)
        end
    end)

    receiptPage:RegisterElement("button", {
        label = _U("close"),
        slot = "footer",
        style = {}
    }, function()
        BCCSocietyMenu:Close()
    end)

    receiptPage:RegisterElement("bottomline", {
        slot = "footer",
        style = {}
    })

    BCCSocietyMenu:Open({
        startupPage = receiptPage
    })
end

function OpenBillingMenu(societyData)
    local playerListPage = GetPlayerListMenuPage(false, function(data)
        devPrint("[BillingCommand] Selected target player:" .. data.source)

        local billAmountPage = BCCSocietyMenu:RegisterPage("bcc-society:billAmountPage")

        billAmountPage:RegisterElement("header", {
            value = _U("bill"),
            slot = "header",
            style = {}
        })

        local billAmount = ""
        billAmountPage:RegisterElement("input", {
            label = _U("amount"),
            placeholder = _U("placeholder"),
            style = {}
        }, function(data)
            billAmount = data.value
            devPrint("[BillingCommand] Bill amount entered:" .. billAmount)
        end)

        local billDescription = ""
        billAmountPage:RegisterElement("textarea", {
            label = _U("billDescriptionLabel") or "Description",
            placeholder = _U("billDescriptionPlaceholder") or "What is this bill for?",
            rows = "4",
            resize = false,
            style = {}
        }, function(data)
            billDescription = data.value
            devPrint("[BillingCommand] Bill description entered:" .. billDescription)
        end)
        billAmountPage:RegisterElement("line", {
            slot = "footer",
            style = {}
        })
        billAmountPage:RegisterElement("button", {
            label = _U("confirm"),
            slot = "footer",
            style = {}
        }, function()
            devPrint("[BillingCommand] Confirm pressed. Validating input...")

            if not string.find(billAmount, "-") and not string.find(billAmount, "'") and not string.find(billAmount, '"') then
                devPrint("[BillingCommand] Input is clean. Sending RPC: BillPlayer")

                BccUtils.RPC:Call("bcc-society:BillPlayer", {
                    playerServerId = data.source,
                    amount = billAmount,
                    description = billDescription,
                    societyId = societyData.business_id -- Add this!
                }, function(success, errorMsg)
                    if success then
                        devPrint("[BillingCommand] Billing successful.")
                        Core.NotifyRightTip(_U("billSuccess"), 4000)
                    else
                        devPrint("[BillingCommand] Billing failed:" .. errorMsg)
                        Core.NotifyRightTip(errorMsg or _U("billingFailed"), 4000)
                    end
                end)
                BCCSocietyMenu:Close()
            else
                devPrint("[BillingCommand] Input validation failed.")
                Core.NotifyRightTip(_U("inputProtectionError"), 4000)
            end
        end)
        billAmountPage:RegisterElement("bottomline", {
            slot = "footer",
            style = {}
        })
        billAmountPage:RouteTo()
    end, function()
        devPrint("[BillingCommand] Player list menu closed.")
        BCCSocietyMenu:Close()
    end)

    BCCSocietyMenu:Open({
        startupPage = playerListPage
    })
end
