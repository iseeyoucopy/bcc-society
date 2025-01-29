BccUtils.RPC:Register("bcc-society:GetAllSocietyJobsPlayerEmployedAt", function(params, cb, recSource)
    local user = Core.getUser(recSource) --[[@as User]]  
    if not user then return end -- is player in session?
    local char = user.getUsedCharacter --[[@as Character]]
    --local user = Core.getUser(recSource)
    --local char = user.getUsedCharacter
    local jobs = SocietyAPI.MiscAPI:GetAllSocietyJobsFromSocietiesPlayerEmployedAtOrOwns(char.charIdentifier)
    if jobs then
        return cb(jobs)
    else
        return cb(false)
    end
end)

RegisterServerEvent("bcc-society:UpdateJob", function(jobName, societyId)
    local _source = source
    local user = Core.getUser(_source)
    local char = user.getUsedCharacter
    local society = SocietyAPI:GetSociety(societyId)
    if society then
        local employeeRank = society:GetEmployeeRank(char.charIdentifier)
        if employeeRank then
            local jobGrade
            if employeeRank == 'none' then
                Core.NotifyRightTip(_source, _U("noRankSetCanNotSwitchJob"), 4000)
            else
                if employeeRank ~= "owner" then
                    jobGrade = society:GetRankInfo(employeeRank).society_job_rank
                else
                    jobGrade = society:GetSocietyInfo().max_job_grade
                end
                local grade = tonumber(jobGrade)
                if not grade then
                    grade = 0
                end
                char.setJob(jobName)
                char.setJobGrade(grade)
                Core.NotifyRightTip(_source, _U("jobChanged"), 4000)
            end
        end
    end
end)

-- Toggle ON Duty Event
RegisterServerEvent("bcc-society:ToggleOnDuty", function()
    local _source = source
    local user = Core.getUser(source)
    if not user then return end
    local character = user.getUsedCharacter

    local charJob = character.job
    local charJobGrade = character.jobGrade

    -- Check if the player is employed in `bcc_society_employees`
    local employmentData = MySQL.query.await("SELECT * FROM bcc_society_employees WHERE employee_id = ?",
        { character.charIdentifier })
    if not employmentData or #employmentData == 0 then
        Core.NotifyRightTip(_source, "You are not employed in a society and cannot toggle duty status.", 4000)
        return
    end

    -- Check if player is actually off duty
    if string.sub(charJob, 1, 3) ~= "off" then
        Core.NotifyRightTip(_source, "You are already on duty!", 4000)
        return
    end

    -- Switch to on-duty (remove "off" prefix)
    local onDutyJob = string.sub(charJob, 4)
 
    -- Alternative method if above doesn't work
    if character.job == charJob then  -- If job hasn't changed, try alternative method
        character.setJob(onDutyJob)     -- Method 2 with colon
    end

    Core.NotifyRightTip(_source, _U("onDuty"), 4000)

    -- Update employee rank in the database
    MySQL.query.await("UPDATE bcc_society_employees SET employee_rank = ? WHERE employee_id = ?",
        { onDutyJob, character.charIdentifier })

end)

RegisterServerEvent("bcc-society:ToggleOffDuty", function()
    local _source = source
    local user = Core.getUser(source)
    if not user then return end
    local character = user.getUsedCharacter

    -- Get the job name - adjust this based on the actual structure
    local charJob = character.job -- or character.job[1] depending on the structure
    
    -- Check if the player is employed in `bcc_society_employees`
    local employmentData = MySQL.query.await("SELECT * FROM bcc_society_employees WHERE employee_id = ?",
        { character.charIdentifier })
    if not employmentData or #employmentData == 0 then
        Core.NotifyRightTip(_source, "You are not employed in a society and cannot toggle duty status.", 4000)
        return
    end

    -- Check if player is actually on duty
    if string.sub(charJob, 1, 3) == "off" then
        Core.NotifyRightTip(_source, "You are already off duty!", 4000)
        return
    end

    -- Switch to off-duty (add "off" prefix)
    local offDutyJob = "off" .. charJob
    
    -- Try to set the new job
    character.setJob(offDutyJob)
    
    Core.NotifyRightTip(_source, _U("offDuty"), 4000)

    -- Update employee rank in the database
    MySQL.query.await("UPDATE bcc_society_employees SET employee_rank = ? WHERE employee_id = ?",
        { offDutyJob, character.charIdentifier })
end)

-- Server Restart/Stop Handler
AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
        return
    end

    local activeEmployees = MySQL.query.await("SELECT * FROM bcc_society_employees WHERE employee_rank NOT LIKE 'off%'")

    if not activeEmployees then
        return
    end

    -- Set all active employees to off-duty
    for _, employee in ipairs(activeEmployees) do
        local currentJob = employee.employee_rank
        local offDutyJob = "off" .. currentJob
        local _source = source
        local user = Core.getUser(employee.employee_id)
        if not user then return end
        local char = user.getUsedCharacter
        if char then
            char.setJob(offDutyJob)
        else
            print("Character not found for employee ID: " .. employee.employee_id)
        end

        -- Update database
        MySQL.query.await("UPDATE bcc_society_employees SET employee_rank = ? WHERE employee_id = ?",
            { offDutyJob, employee.employee_id })
    end
end)
