RegisterCommand(Config.openJobManagementMenuCommandName, function()
    local jobManagementPage = BCCSocietyMenu:RegisterPage("bcc-society:jobManagementPage")
    jobManagementPage:RegisterElement("header", {
        value = _U("jobManagement"),
        slot = "header",
        style = {}
    })
    local jobs = BccUtils.RPC:CallAsync("bcc-society:GetAllSocietyJobsPlayerEmployedAt", nil)
    if jobs then
        for k, v in pairs(jobs) do
            jobManagementPage:RegisterElement("button", {
                label = v.jobName,
                style = {}
            }, function()
                TriggerServerEvent('bcc-society:UpdateJob', v.jobName, v.societyId)
            end)
        end
    end
    BCCSocietyMenu:Open({
        startupPage = jobManagementPage
    })
end)

RegisterCommand(Config.toggleDutyCommandName, function()
    TriggerServerEvent('bcc-society:ToggleDuty')
end)