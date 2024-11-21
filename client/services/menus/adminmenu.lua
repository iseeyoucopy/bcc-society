RegisterCommand(Config.adminMenuCommandName, function()
    if IsAdmin then
        local societies = BccUtils.RPC:CallAsync("bcc-society:GetAllSocieties")
        if #societies > 0 then
            local adminPage = BCCSocietyMenu:RegisterPage("bcc-society:adminPage")
            adminPage:RegisterElement("header", {
                value = _U("adminMenu"),
                slot = "header",
                style = {}
            })

            for k, v in pairs(societies) do
                adminPage:RegisterElement("button", {
                    label = v.business_name,
                    style = {}
                }, function()
                    local indivudalSocietyPage = BCCSocietyMenu:RegisterPage("bcc-society:indivudalSocietyPage")
                    indivudalSocietyPage:RegisterElement("header", {
                        value = v.business_name,
                        slot = "header",
                        style = {}
                    })

                    indivudalSocietyPage:RegisterElement("button", {
                        label = _U("deleteSociety"),
                        style = {}
                    }, function()
                        local confirmationPage = BCCSocietyMenu:RegisterPage("bcc-society:confirmationPage")
                        confirmationPage:RegisterElement("header", {
                            value = _U("confirm"),
                            slot = "header",
                            style = {}
                        })

                        confirmationPage:RegisterElement("button", {
                            label = _U("yes"),
                            style = {}
                        }, function()
                            TriggerServerEvent("bcc-society:AdminManageSociety", v.business_id, true)
                            Core.NotifyRightTip(_U("deleted"), 4000)
                            BCCSocietyMenu:Close()
                        end)
                        confirmationPage:RegisterElement("button", {
                            label = _U("no"),
                            style = {}
                        }, function()
                            indivudalSocietyPage:RouteTo()
                        end)

                        indivudalSocietyPage:RegisterElement("button", {
                            label = _U("back"),
                            style = {}
                        }, function()
                            adminPage:RouteTo()
                        end)

                        confirmationPage:RouteTo()
                    end)
                    local societyTaxAmount = v.tax_amount
                    indivudalSocietyPage:RegisterElement('input', {
                        label = _U("taxChange"),
                        placeholder = _U("placeholder"),
                        style = {}
                    }, function(data)
                        societyTaxAmount = data.value
                    end)
                    local name = v.business_name
                    indivudalSocietyPage:RegisterElement("input", {
                        label = _U("changeName"),
                        placeholder = _U("placeholder"),
                        style = {}
                    }, function(data)
                        name = data.value
                    end)
                    local job = v.society_job
                    indivudalSocietyPage:RegisterElement("input", {
                        label = _U("changeJob"),
                        placeholder = _U("placeholder"),
                        style = {}
                    }, function(data)
                        job = data.value
                    end)
                    local invLimit = v.inv_limit
                    indivudalSocietyPage:RegisterElement("input", {
                        label = _U("invLimitChange"),
                        placeholder = _U("placeholder"),
                        style = {}
                    }, function(data)
                        invLimit = data.value
                    end)
                    local blipHash = v.blip_hash
                    indivudalSocietyPage:RegisterElement("button", {
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
                            for e, a in pairs(Config.blips) do
                                blipPage:RegisterElement("button", {
                                    label = a.blipName,
                                    style = {}
                                }, function()
                                    blipHash = a.blipHash
                                    Core.NotifyRightTip(_U("blipSet"), 4000)
                                    indivudalSocietyPage:RouteTo()
                                end)
                            end

                            blipPage:RegisterElement("button", {
                                label = _U("back"),
                                style = {}
                            }, function()
                                indivudalSocietyPage:RouteTo()
                            end)

                            blipPage:RouteTo()
                        else
                            Core.NotifyRightTip(_U("noBlipsInConfig"), 4000)
                        end
                    end)

                    indivudalSocietyPage:RegisterElement("button", {
                        label = _U("confirm"),
                        style = {}
                    }, function()
                        TriggerServerEvent("bcc-society:AdminManageSociety", v.business_id, false, societyTaxAmount, name, invLimit, blipHash, job)
                        Core.NotifyRightTip(_U("changed"), 4000)
                        BCCSocietyMenu:Close()
                    end)

                    indivudalSocietyPage:RegisterElement("button", {
                        label = _U("back"),
                        style = {}
                    }, function()
                        BCCSocietyMenu:Close()
                    end)

                    indivudalSocietyPage:RouteTo()
                end)
            end

            BCCSocietyMenu:Open({
                startupPage = adminPage
            })
        else
            Core.NotifyRightTip(_U("noSocieties"), 4000)
        end
    end
end)