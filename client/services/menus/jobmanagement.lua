RegisterCommand(Config.openJobManagementMenuCommandName, function()
    local jobManagementPage = BCCSocietyMenu:RegisterPage("bcc-society:jobManagementPage")
    jobManagementPage:RegisterElement("header", {
        value = _U("jobManagement"),
        slot = "header",
        style = {}
    })
    local jobs = BccUtils.RPC:CallAsync("bcc-society:GetAllSocietyJobsPlayerEmployedAt", nil)
    if jobs then
        for _, v in ipairs(jobs) do
            local ranks = v.ranks or {}
            if #ranks > 0 then
                for _, rank in ipairs(ranks) do
                    local rankLabel = rank.displayName or string.format('%s (%s)', v.businessName or (v.displayName or 'Society'), rank.rankLabel or rank.rankName or '')
                    jobManagementPage:RegisterElement("button", {
                        label = rankLabel,
                        style = {}
                    }, function()
                        TriggerServerEvent('bcc-society:UpdateJob', rank.jobName or rank.rankName, v.societyId, rank.rankName)
                    end)
                end
            else
                local label = v.displayName or v.jobName or (v.businessName or ('Society #' .. tostring(v.societyId)))
                jobManagementPage:RegisterElement("button", {
                    label = label,
                    style = {}
                }, function()
                    TriggerServerEvent('bcc-society:UpdateJob', v.jobName, v.societyId)
                end)
            end
        end
    end
    BCCSocietyMenu:Open({
        startupPage = jobManagementPage
    })
end)

RegisterCommand(Config.toggleOnDutyCommandName, function()
    TriggerServerEvent('bcc-society:ToggleOnDuty')
end)

RegisterCommand(Config.toggleOffDutyCommandName, function()
    TriggerServerEvent('bcc-society:ToggleOffDuty')
end)

if Config.switchJobCommandName and Config.switchJobCommandName ~= "" then
    RegisterCommand(Config.switchJobCommandName, function(_, args)
        if not args or not args[1] then
            Notify(_U("switchJobUsage"), "error", 4000)
            return
        end

        TriggerServerEvent("bcc-society:SwitchJobCommand", table.concat(args, " "))
    end)
end
