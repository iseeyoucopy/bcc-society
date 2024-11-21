function ManageSocietyMenu(societyData, societyCoordsVector3, isOwner)
    BCCSocietyMenu:Close()

    local employeeData = nil
    if not isOwner then
        employeeData = BccUtils.RPC:CallAsync("bcc-society:GetEmployeeData", {socId = societyData.business_id, recType = "rankData"})
    end

    local manageSocietyPage = BCCSocietyMenu:RegisterPage("bcc-society:manageSocietyPage")
    manageSocietyPage:RegisterElement("header", {
        value = societyData.business_name,
        slot = "header",
        style = {}
    })
    if isOwner or employeeData ~= nil and employeeData ~= false and employeeData.rank_can_edit_ranks == "true" then
        -- Add 'Collect Payment' button in the society menu
        manageSocietyPage:RegisterElement("button", {
            label = _U('collectPayment'),
            style = {}
        }, function()
            -- Request the payment amount using a callback
            BccUtils.RPC:Call("bcc-society:GetPaymentAmount", {}, function(paymentAmount)
                if not paymentAmount then
                    Core.NotifyRightTip(_U('nothingToCollect'), 4000)
                    return
                end

                -- Create a new page for payment confirmation
                local paymentPage = BCCSocietyMenu:RegisterPage("bcc-society:paymentPage")

                -- Add header to the payment page
                paymentPage:RegisterElement("header", {
                    value = _U('payment'),
                    slot = "header",
                    style = {}
                })

                -- Display payment confirmation message with amount
                paymentPage:RegisterElement("html", {
                    value = string.format([[
                        <div style="font-family: Arial, sans-serif; padding: 10px;">
                            <p style="font-size: 14px; color: #333;">Are you sure you want to collect your payment of $%s?</p>
                        </div>
                    ]], tostring(paymentAmount)),
                    style = {}
                })

                -- Add 'Yes' button to confirm payment collection
                paymentPage:RegisterElement("button", {
                    label = "Yes",
                    style = {}
                }, function()
                    -- Trigger the server event to collect payment for the player
                    TriggerServerEvent('bcc-society:CollectPayment')
                    manageSocietyPage:RouteTo()
                end)

                -- Add 'No' button to cancel the payment collection
                paymentPage:RegisterElement("button", {
                    label = "No",
                    style = {}
                }, function()
                    -- Return to the previous menu without collecting payment
                    manageSocietyPage:RouteTo()
                end)

                -- Route to the payment page
                paymentPage:RouteTo()
            end)
        end)

        manageSocietyPage:RegisterElement("button", {
            label = _U("ranks"),
            style = {}
        }, function()
            local rankName, rankPay, payIncrement = nil, nil, nil

            local ranksPage = BCCSocietyMenu:RegisterPage("bcc-society:ranksPage")
            ranksPage:RegisterElement("header", {
                value = _U("ranks"),
                slot = "header",
                style = {}
            })

            ranksPage:RegisterElement("button", {
                label = _U("addRank"),
                style = {}
            }, function()
                local addRankPage = BCCSocietyMenu:RegisterPage("bcc-society:addRankPage")
                local toggleBlip, withrdraw, deposit, editWebhook, editRanks, manageEmployees, openInv, canManageStore, rankJobGrade, canBillPlayers = "false", 'false', 'false', 'false', 'false', 'false', 'false', 'false', 0, 'false'
                local rankLabel -- New variable for rank_label
            
                addRankPage:RegisterElement("header", {
                    value = _U("addRank"),
                    slot = "header",
                    style = {}
                })
            
                addRankPage:RegisterElement("input", {
                    label = _U("rankName"),
                    placeholder = _U("placeholder"),
                    style = {}
                }, function(data)
                    rankName = data.value
                end)
            
                addRankPage:RegisterElement("input", {
                    label = _U("rankLabel"), -- New input for rank label
                    placeholder = _U("placeholder"),
                    style = {}
                }, function(data)
                    rankLabel = data.value
                end)
            
                addRankPage:RegisterElement("input", {
                    label = _U("rankPay"),
                    placeholder = _U("placeholder"),
                    style = {}
                }, function(data)
                    rankPay = data.value
                end)
            
                addRankPage:RegisterElement("input", {
                    label = _U("rankJobGrade"),
                    placeholder = _U("placeholder"),
                    style = {}
                }, function(data)
                    rankJobGrade = data.value
                end)
            
                addRankPage:RegisterElement("input", {
                    label = _U("payIncrement"),
                    placeholder = _U("placeholder"),
                    style = {}
                }, function(data)
                    payIncrement = data.value
                end)
            
                -- Remaining toggle elements
                addRankPage:RegisterElement('toggle', {
                    label = _U("canToggleBlip"),
                    start = false
                }, function(data)
                    toggleBlip = data.value and "true" or "false"
                end)
            
                addRankPage:RegisterElement('toggle', {
                    label = _U("canBillPlayers"),
                    start = false
                }, function(data)
                    canBillPlayers = data.value and "true" or "false"
                end)
            
                addRankPage:RegisterElement("toggle", {
                    label = _U("canEditWebhook"),
                    start = false
                }, function(data)
                    editWebhook = data.value and "true" or "false"
                end)
            
                addRankPage:RegisterElement('toggle', {
                    label = _U("canWithdraw"),
                    start = false
                }, function(data)
                    withrdraw = data.value and "true" or "false"
                end)
            
                addRankPage:RegisterElement('toggle', {
                    label = _U("canDeposit"),
                    start = false
                }, function(data)
                    deposit = data.value and "true" or "false"
                end)
            
                addRankPage:RegisterElement('toggle', {
                    label = _U("canEditRanks"),
                    start = false
                }, function(data)
                    editRanks = data.value and "true" or "false"
                end)
            
                addRankPage:RegisterElement('toggle', {
                    label = _U("canManageEmployees"),
                    start = false
                }, function(data)
                    manageEmployees = data.value and "true" or "false"
                end)
            
                addRankPage:RegisterElement('toggle', {
                    label = _U("canOpenInventory"),
                    start = false
                }, function(data)
                    openInv = data.value and "true" or "false"
                end)
            
                addRankPage:RegisterElement("line", {
                    slot = 'footer',
                    style = {}
                })
            
                addRankPage:RegisterElement("button", {
                    label = _U("confirm"),
                    slot = "footer",
                    style = {}
                }, function()
                    if rankName ~= nil and rankLabel ~= nil and rankPay ~= nil and tonumber(rankPay) > -1 and payIncrement ~= nil and tonumber(payIncrement) > 0 then
                        if tonumber(societyData.max_job_grade) <= tonumber(rankJobGrade) then
                            rankJobGrade = tonumber(societyData.max_job_grade) - 1 -- Preventing the rank from being the same as the owner
                        end
                        TriggerServerEvent("bcc-society:RankManagement", "add", societyData.business_id, rankName, rankLabel, rankPay, payIncrement, toggleBlip, withrdraw, deposit, editRanks, manageEmployees, openInv, editWebhook, canManageStore, rankJobGrade, canBillPlayers)
                        ManageSocietyMenu(societyData, societyCoordsVector3, isOwner)
                    else
                        Core.NotifyRightTip(_U("fillAllFields"), 4000)
                    end
                end)
            
                addRankPage:RegisterElement("button", {
                    label = _U("back"),
                    slot = 'footer',
                    style = {}
                }, function()
                    ranksPage:RouteTo()
                end)
            
                addRankPage:RegisterElement("bottomline", {
                    slot = 'footer',
                    style = {}
                })
            
                addRankPage:RouteTo()
            end)            
            ranksPage:RegisterElement("button", {
                label = _U("viewRanks"),
                style = {}
            }, function()
                local retval = BccUtils.RPC:CallAsync("bcc-society:GetAllRanks", {socId = societyData.business_id})
                if retval then
                    local viewRanksPage = BCCSocietyMenu:RegisterPage("bcc-society:viewRanksPage")
                    viewRanksPage:RegisterElement("header", {
                        value = _U("ranks"),
                        slot = "header",
                        style = {}
                    })
                    for k, v in pairs(retval) do
                        viewRanksPage:RegisterElement("button", {
                            label = v.rank_name,
                            style = {}
                        }, function()
                            local individualRankPage = BCCSocietyMenu:RegisterPage("bcc-society:individualRankPage")
                            local toggleBlip, withrdraw, deposit, editRanks, manageEmployees, openInv, editWebhook, canManageStore, rankJobGrade, canBillPlayers = v.rank_can_toggle_blip, v.rank_can_withdraw, v.rank_can_deposit, v.rank_can_edit_ranks, v.rank_can_manage_employees, v.rank_can_open_inventory, v.rank_can_edit_webhook_link, v.rank_can_manage_store, v.society_job_rank, v.rank_can_bill_players
                            individualRankPage:RegisterElement("header", {
                                value = v.rank_name,
                                slot = "header",
                                style = {}
                            })
                            
                            local htmlRankDesign = {
                                [[
                                    <div style="font-family: Arial, sans-serif; padding: 10px;">
                                        <h2 style="margin: 0; font-size: 18px; color: #4CAF50;">]] .. _U("rankName") .. ": " .. v.rank_name .. [[</h2>
                                        <p style="margin: 5px 0 0; font-size: 14px; color: #333;">
                                            <strong>]] .. _U("rankPay") .. [[:</strong> ]] .. v.rank_pay .. [[<br>
                                            <strong>]] .. _U("payIncrementDisplay") .. [[:</strong> ]] .. v.rank_pay_increment .. [[
                                        </p>
                                    </div>
                                ]]
                            }
                            
                            individualRankPage:RegisterElement("html", { 
                                value = htmlRankDesign
                            })
                          
                                                       
                            local rankPayUpdate, payIncrementUpdate = v.rank_pay, v.rank_pay_increment
                            individualRankPage:RegisterElement('input', {
                                label = _U("editRankPay"),
                                placeholder = _U("placeholder"),
                                style = {}
                            }, function(data)
                                rankPayUpdate = data.value
                            end)
                            individualRankPage:RegisterElement('input', {
                                label = _U("editRankPayIncrement"),
                                placeholder = _U("placeholder"),
                                style = {}
                            }, function(data)
                                payIncrementUpdate = data.value
                            end)
                            individualRankPage:RegisterElement("input", {
                                label = _U("rankJobGrade"),
                                placeholder = _U("placeholder"),
                                style = {}
                            }, function(data)
                                rankJobGrade = data.value
                            end)
                            local stringToBoolean = { ["true"] = true, ["false"] = false }
                            individualRankPage:RegisterElement('toggle', {
                                label = _U("canToggleBlip"),
                                start = stringToBoolean[toggleBlip]
                            }, function(data)
                                if data.value then
                                    toggleBlip = "true"
                                else
                                    toggleBlip = "false"
                                end
                            end)
                            individualRankPage:RegisterElement('toggle', {
                                label = _U("canBillPlayers"),
                                start = false
                            }, function(data)
                                if data.value then
                                    canBillPlayers = "true"
                                else
                                    canBillPlayers = "false"
                                end
                            end)
                            individualRankPage:RegisterElement("toggle", {
                                label = _U("canEditWebhook"),
                                start = stringToBoolean[editWebhook]
                            }, function(data)
                                if data.value then
                                    editWebhook = "true"
                                else
                                    editWebhook = "false"
                                end
                            end)

                            individualRankPage:RegisterElement('toggle', {
                                label = _U("canWithdraw"),
                                start = stringToBoolean[withrdraw]
                            }, function(data)
                                if data.value then
                                    withrdraw = "true"
                                else
                                    withrdraw = "false"
                                end
                            end)
                            individualRankPage:RegisterElement('toggle', {
                                label = _U("canDeposit"),
                                start = stringToBoolean[deposit]
                            }, function(data)
                                if data.value then
                                    deposit = "true"
                                else
                                    deposit = "false"
                                end
                            end)
                            individualRankPage:RegisterElement('toggle', {
                                label = _U("canEditRanks"),
                                start = stringToBoolean[editRanks]
                            }, function(data)
                                if data.value then
                                    editRanks = "true"
                                else
                                    editRanks = "false"
                                end
                            end)
                            individualRankPage:RegisterElement('toggle', {
                                label = _U("canManageEmployees"),
                                start = stringToBoolean[manageEmployees]
                            }, function(data)
                                if data.value then
                                    manageEmployees = "true"
                                else
                                    manageEmployees = "false"
                                end
                            end)
                            individualRankPage:RegisterElement('toggle', {
                                label = _U("canOpenInventory"),
                                start = stringToBoolean[openInv]
                            }, function(data)
                                if data.value then
                                    openInv = "true"
                                else
                                    openInv = "false"
                                end
                            end)

                            individualRankPage:RegisterElement("line", {
                                slot = 'footer',
                                style = {}
                            })

                            individualRankPage:RegisterElement("button", {
                                label = _U("confirm"),
                                slot = 'footer',
                                style = {}
                            }, function()
                                local rankPayNumber = tonumber(rankPayUpdate)
                                local payIncrementNumber = tonumber(payIncrementUpdate)

                                if payIncrementNumber ~= nil and rankPayNumber ~= nil then
                                    if tonumber(societyData.max_job_grade) <= tonumber(rankJobGrade) then
                                        rankJobGrade = tonumber(societyData.max_job_grade) - 1 -- Preventing the rank from being the same as the owner
                                    end

                                    -- Use the existing `v.rank_label` for `rankLabel` if it wasn’t modified
                                    local rankLabel = v.rank_label -- Replace "Default Label" if a different default is preferred

                                    TriggerServerEvent('bcc-society:RankManagement', "update", societyData.business_id, v.rank_name, rankLabel, rankPayNumber, payIncrementNumber, toggleBlip, withrdraw, deposit, editRanks, manageEmployees, openInv, editWebhook, canManageStore, rankJobGrade, canBillPlayers)
                                    ManageSocietyMenu(societyData, societyCoordsVector3, isOwner)
                                else
                                    Core.NotifyRightTip(_U("fillAllFields"), 4000)
                                end

                            end)

                            individualRankPage:RegisterElement("button", {
                                label = _U("deleteRank"),
                                slot = 'footer',
                                style = {}
                            }, function()
                                TriggerServerEvent("bcc-society:RankManagement", "delete", societyData.business_id, v.rank_name)
                                ManageSocietyMenu(societyData, societyCoordsVector3, isOwner)
                            end)

                            individualRankPage:RegisterElement("button", {
                                label = _U("back"),
                                slot = 'footer',
                                style = {}
                            }, function()
                                viewRanksPage:RouteTo()
                            end)

                            individualRankPage:RegisterElement("bottomline", {
                                slot = 'footer',
                                style = {}
                            })

                            individualRankPage:RouteTo()
                        end)
                    end

                    viewRanksPage:RegisterElement("line", {
                        slot = 'footer',
                        style = {}
                    })
                    
                    viewRanksPage:RegisterElement("button", {
                        label = _U("back"),
                        slot = 'footer',
                        style = {}
                    }, function()
                        ranksPage:RouteTo()
                    end)

                    viewRanksPage:RegisterElement("bottomline", {
                        slot = 'footer',
                        style = {}
                    })

                    viewRanksPage:RouteTo()
                else
                    Core.NotifyRightTip(_U("noRanks"), 4000)
                end
            end)

            ranksPage:RegisterElement("line", {
                slot = 'footer',
                style = {}
            })
            
            ranksPage:RegisterElement("button", {
                label = _U("back"),
                slot = 'footer',
                style = {}
            }, function()
                manageSocietyPage:RouteTo()
            end)

            ranksPage:RegisterElement("bottomline", {
                slot = 'footer',
                style = {}
            })

            ranksPage:RouteTo()
        end)
    end
    if isOwner or employeeData ~= nil and employeeData ~= false and employeeData.rank_can_toggle_blip == "true" then
        manageSocietyPage:RegisterElement("button", {
            label = _U("toggleBlip"),
            style = {}
        }, function()
            local toggleBlipPage = BCCSocietyMenu:RegisterPage("bcc-society:toggleBlipPage")
            toggleBlipPage:RegisterElement("header", {
                value = _U("toggleBlip"),
                slot = "header",
                style = {}
            })
            toggleBlipPage:RegisterElement("button", {
                label = _U("toggleOn"),
                style = {}
            }, function()
                TriggerServerEvent("bcc-society:ServerSyncBlips", societyData.business_name, societyData.blip_hash, societyCoordsVector3, societyData.business_id, false)
            end)
            toggleBlipPage:RegisterElement("button", {
                label = _U("toggleOff"),
                style = {}
            }, function()
                TriggerServerEvent("bcc-society:ServerSyncBlips", societyData.business_name, societyData.blip_hash, societyCoordsVector3, societyData.business_id, true)
            end)

            toggleBlipPage:RegisterElement("line", {
                slot = 'footer',
                style = {}
            })

            toggleBlipPage:RegisterElement("button", {
                label = _U("back"),
                slot = 'footer',
                style = {}
            }, function()
                manageSocietyPage:RouteTo()
            end)

            toggleBlipPage:RegisterElement("bottomline", {
                slot = 'footer',
                style = {}
            })

            toggleBlipPage:RouteTo()
        end)
    end
    if isOwner or employeeData ~= nil and employeeData ~= false and employeeData.rank_can_withdraw == "true" or employeeData ~= nil and employeeData ~= false and employeeData.rank_can_deposit == "true" then
        manageSocietyPage:RegisterElement('button', {
            label = _U("ledger"),
            style = {}
        }, function()
            local ledgerPage = BCCSocietyMenu:RegisterPage("bcc-society:ledgerPage")
            ledgerPage:RegisterElement("header", {
                value = _U("ledger"),
                slot = "header",
                style = {}
            })

            ledgerPage:RegisterElement("subheader", {
                value = _U("ledgerAmount") .. BccUtils.RPC:CallAsync("bcc-society:GetLedgerData", {socId = societyData.business_id}),
                slot = "header",
                style = {}
            })
            ledgerPage:RegisterElement("subheader", {
                value = _U("taxAmount") .. societyData.tax_amount,
                slot = "header",
                style = {}
            })
            ledgerPage:RegisterElement('line', {
                slot = "header",
                style = {}
            })
            local depositAmount, withdrawAmount = '', ''
            if isOwner or employeeData ~= nil and employeeData.rank_can_deposit == "true" then
                ledgerPage:RegisterElement('input', {
                    label = _U("deposit"),
                    placeholder = _U("amount"),
                    style = {}
                }, function(data)
                    if string.find(data.value, "-") or string.find(data.value, "'") or string.find(data.value, '"') then -- checking for ' or " to prevent sql injection and - to prevent negative numbers
                        Core.NotifyRightTip(_U("inputProtectionError"), 4000)
                        depositAmount = ''
                    else
                        depositAmount = data.value
                    end
                end)
            end
            if isOwner or employeeData ~= nil and employeeData.rank_can_withdraw == "true" then
                ledgerPage:RegisterElement('input', {
                    label = _U("withdraw"),
                    placeholder = _U("amount"),
                    style = {}
                }, function(data)
                    if string.find(data.value, "-") or string.find(data.value, "'") or string.find(data.value, '"') then -- checking for ' or " to prevent sql injection and - to prevent negative numbers
                        Core.NotifyRightTip(_U("inputProtectionError"), 4000)
                        withdrawAmount = ''
                    else
                        withdrawAmount = data.value
                    end
                end)
            end

            ledgerPage:RegisterElement("line", {
                slot = 'footer',
                style = {}
            })

            if isOwner or employeeData ~= nil and employeeData.rank_can_deposit == "true" or employeeData ~= nil and employeeData.rank_can_withdraw == "true" then
                ledgerPage:RegisterElement("button", {
                    label = _U("confirm"),
                    style = {}
                }, function()
                    if depositAmount ~= '' then
                        TriggerServerEvent("bcc-society:LedgerManagement", societyData.business_id, depositAmount, "deposit")
                        ManageSocietyMenu(societyData, societyCoordsVector3, isOwner)
                    end
                    if withdrawAmount ~= '' then
                        TriggerServerEvent("bcc-society:LedgerManagement", societyData.business_id, withdrawAmount, "withdraw")
                        ManageSocietyMenu(societyData, societyCoordsVector3, isOwner)
                    end
                    if depositAmount == '' and withdrawAmount == '' then
                        Core.NotifyRightTip(_U("fillAllFields"), 4000)
                    end
                end)
            end

            ledgerPage:RegisterElement("button", {
                label = _U("back"),
                slot = 'footer',
                style = {}
            }, function()
                manageSocietyPage:RouteTo()
            end)

            ledgerPage:RegisterElement("bottomline", {
                slot = 'footer',
                style = {}
            })

            ledgerPage:RouteTo()
        end)
    end
    if isOwner or employeeData ~= nil and employeeData ~= false and employeeData.rank_can_open_inventory == "true" then
        manageSocietyPage:RegisterElement("button", {
            label = _U("inventory"),
            style = {}
        }, function()
            local inventoryPage = BCCSocietyMenu:RegisterPage("bcc-society:inventoryPage")
            inventoryPage:RegisterElement("header", {
                value = _U("inventory"),
                slot = "header",
                style = {}
            })
            local stageData = BccUtils.RPC:CallAsync("bcc-society:GetInventoryStages", {socId = societyData.business_id})
            inventoryPage:RegisterElement("subheader", {
                value = _U("currentStage") .. tostring(stageData.inventory_current_stage),
                slot = "header",
                style = {}
            })
            inventoryPage:RegisterElement('line', {
                slot = "header",
                style = {}
            })
            inventoryPage:RegisterElement("button", {
                label = _U("openInventory"),
                style = {}
            }, function()
                TriggerServerEvent("bcc-society:openInventory", societyData.business_id, societyData.business_name, tonumber(societyData.inv_limit), tonumber(stageData.inventory_current_stage))
            end)
            if stageData.nextStage then
                inventoryPage:RegisterElement("button", {
                    label = _U("upgradeStage") .. tostring(tonumber(stageData.nextStage.stage)) .. _U("upgradeFor") .. tostring(stageData.nextStage.cost) .. _U("upgradeGainSlots") .. tostring(stageData.nextStage.slotIncrease),
                    style = {}
                }, function()
                    if BccUtils.RPC:CallAsync("bcc-society:UpgradeInventory", {socId = societyData.business_id, cost = stageData.nextStage.cost, nextStage = stageData.nextStage.stage}) then
                        Core.NotifyRightTip(_U("inventoryUpgraded"), 4000)
                        ManageSocietyMenu(societyData, societyCoordsVector3, isOwner)
                    else
                        Core.NotifyRightTip(_U("notEnoughCash"), 4000)
                    end
                end)
            end

            inventoryPage:RegisterElement("line", {
                slot = 'footer',
                style = {}
            })

            inventoryPage:RegisterElement("button", {
                label = _U("back"),
                slot = 'footer',
                style = {}
            }, function()
                manageSocietyPage:RouteTo()
            end)

            inventoryPage:RegisterElement("bottomline", {
                slot = 'footer',
                style = {}
            })

            inventoryPage:RouteTo()
        end)
    end
    if isOwner or employeeData ~= nil and employeeData ~= false and employeeData.rank_can_manage_employees == "true" then
        manageSocietyPage:RegisterElement("button", {
            label = _U("manageEmployees"),
            style = {}
        }, function()
            --local employeesToExclude = BccUtils.RPC:CallAsync("bcc-society:GetAllEmployeesData", {socId = societyData.business_id, recType = "hire"}) -- This has to be here as if it is inside of the same function we call the GetPlayerlistmenu function it will not work and will say callback not registered (Believe its something to do with context investigate more)
            local employeePage = BCCSocietyMenu:RegisterPage("bcc-society:employeePage")
            employeePage:RegisterElement("header", {
                value = _U("manageEmployees"),
                slot = "header",
                style = {}
            })
            employeePage:RegisterElement("button", {
                label = _U("hireEmployee"),
                style = {}
            }, function()
                local hirePlayerPage = GetPlayerListMenuPage(false, function(data)
                    local confirmHirePage = BCCSocietyMenu:RegisterPage("bcc-society:confirmHirePage")
                    confirmHirePage:RegisterElement("header", {
                        value = _U("confirm"),
                        slot = "header",
                        style = {}
                    })
                    confirmHirePage:RegisterElement("button", {
                        label = _U("yes"),
                        style = {}
                    }, function()
                        TriggerServerEvent("bcc-society:PlayerHired", societyData.business_id, data.charId, data.source, societyData)
                        manageSocietyPage:RouteTo()
                    end)
                    confirmHirePage:RegisterElement("button", {
                        label = _U("no"),
                        style = {}
                    }, function()
                        employeePage:RouteTo()
                    end)
                    confirmHirePage:RouteTo()
                end, function()
                    employeePage:RouteTo()
                end)
                hirePlayerPage:RouteTo()
            end)
            employeePage:RegisterElement("button", {
                label = _U("viewEmployees"),
                style = {}
            }, function()
                local employees = BccUtils.RPC:CallAsync("bcc-society:GetAllEmployeesData", {socId = societyData.business_id, recType = "viewEmployees"})
                if employees then
                    if #employees > 0 then
                        local viewEmployeesPage = BCCSocietyMenu:RegisterPage("bcc-society:viewEmployeesPage")
                        viewEmployeesPage:RegisterElement("header", {
                            value = _U("employees"),
                            slot = "header",
                            style = {}
                        })

                        for k, v in pairs(employees) do
                            viewEmployeesPage:RegisterElement("button", {
                                label = v.employeeName,
                                style = {}
                            }, function()
                                local individualEmployeePage = BCCSocietyMenu:RegisterPage("bcc-society:individualEmployeePage")
                                individualEmployeePage:RegisterElement("header", {
                                    value = v.employeeName,
                                    slot = "header",
                                    style = {}
                                })

                                individualEmployeePage:RegisterElement('button', {
                                    label = _U("fireEmployee"),
                                    style = {}
                                }, function()
                                    local confirmFirePage = BCCSocietyMenu:RegisterPage("bcc-society:confirmFirePage")
                                    confirmFirePage:RegisterElement("header", {
                                        value = _U("confirm"),
                                        slot = "header",
                                        style = {}
                                    })

                                    confirmFirePage:RegisterElement("button", {
                                        label = _U("yes"),
                                        style = {}
                                    }, function()
                                        TriggerServerEvent("bcc-society:FireEmployee", societyData.business_id, v.charId, societyData)
                                        ManageSocietyMenu(societyData, societyCoordsVector3, isOwner)
                                    end)
                                    confirmFirePage:RegisterElement("button", {
                                        label = _U("no"),
                                        style = {}
                                    }, function()
                                        individualEmployeePage:RouteTo()
                                    end)

                                    confirmFirePage:RouteTo()
                                end)
                                individualEmployeePage:RegisterElement("textdisplay", {
                                    value = _U("employeeCurrentRank") .. v.employeeRank,
                                    style = {}
                                })
                                individualEmployeePage:RegisterElement("button", {
                                    label = _U("changeEmployeeRank"),
                                    style = {}
                                }, function()
                                    local ranks = BccUtils.RPC:CallAsync("bcc-society:GetAllRanks", {socId = societyData.business_id})
                                    local changeRankPage = BCCSocietyMenu:RegisterPage("bcc-society:changeRankPage")
                                    changeRankPage:RegisterElement("header", {
                                        value = _U("changeEmployeeRank"),
                                        slot = "header",
                                        style = {}
                                    })
                                    if ranks then
                                        if #ranks > 0 then
                                            for e, a in pairs(ranks) do
                                                changeRankPage:RegisterElement("button", {
                                                    label = a.rank_name,
                                                    style = {}
                                                }, function()
                                                    TriggerServerEvent("bcc-society:ChangeEmployeeRank", societyData.business_id, a.rank_name, v.charId, societyData.business_name)
                                                    ManageSocietyMenu(societyData, societyCoordsVector3, isOwner)
                                                end)
                                            end
                                            changeRankPage:RegisterElement("button", {
                                                label = _U("back"),
                                                slot = 'footer',
                                                style = {}
                                            }, function()
                                                individualEmployeePage:RouteTo()
                                            end)

                                            changeRankPage:RouteTo()
                                        else
                                            Core.NotifyRightTip(_U("noRanks"), 4000)
                                        end
                                    else
                                        Core.NotifyRightTip(_U("noRanks"), 4000)
                                    end
                                end)

                                individualEmployeePage:RegisterElement("button", {
                                    label = _U("back"),
                                    slot = 'footer',
                                    style = {}
                                }, function()
                                    viewEmployeesPage:RouteTo()
                                end)

                                individualEmployeePage:RouteTo()
                            end)
                        end

                        viewEmployeesPage:RegisterElement("button", {
                            label = _U("back"),
                            slot = 'footer',
                            style = {}
                        }, function()
                            employeePage:RouteTo()
                        end)

                        viewEmployeesPage:RouteTo()
                    else
                        Core.NotifyRightTip(_U("noEmployees"), 4000)
                    end
                else
                    Core.NotifyRightTip(_U("noEmployees"), 4000)
                end
            end)

            employeePage:RegisterElement("button", {
                label = _U("back"),
                slot = 'footer',
                style = {}
            }, function()
                manageSocietyPage:RouteTo()
            end)

            employeePage:RouteTo()
        end)
    end
    if isOwner or employeeData ~= nil and employeeData ~= false and employeeData.rank_can_edit_webhook_link == "true" then
        manageSocietyPage:RegisterElement("button", {
            label = _U("editWebhook"),
            style = {}
        }, function()
            local editWebhookPage = BCCSocietyMenu:RegisterPage("bcc-society:editWebhookPage")
            editWebhookPage:RegisterElement("header", {
                value = _U("editWebhook"),
                slot = "header",
                style = {}
            })
            local webhookLink = ""
            editWebhookPage:RegisterElement('input', {
                label = _U("setWebhook"),
                placeholder = _U("placeholder"),
                style = {}
            }, function(data)
                webhookLink = data.value
            end)
            editWebhookPage:RegisterElement("button", {
                label = _U("confirm"),
                style = {}
            }, function()
                if webhookLink ~= "" then
                    TriggerServerEvent("bcc-society:EditWebhookLink", societyData.business_id, webhookLink)
                    societyData.webhook_link = webhookLink
                    Core.NotifyRightTip(_U("changed"), 4000)
                    ManageSocietyMenu(societyData, societyCoordsVector3, isOwner)
                else
                    Core.NotifyRightTip(_U("fillAllFields"), 4000)
                end
            end)

            editWebhookPage:RegisterElement("button", {
                label = _U("back"),
                slot = 'footer',
                style = {}
            }, function()
                manageSocietyPage:RouteTo()
            end)

            editWebhookPage:RouteTo()
        end)
    end

    BCCSocietyMenu:Open({
        startupPage = manageSocietyPage
    })
end