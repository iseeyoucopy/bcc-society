BccUtils.RPC:Register("bcc-society:GetAllSocietyJobsPlayerEmployedAt", function(params, cb, recSource)
    local char = Core.getUser(recSource)
    local jobs = SocietyAPI.MiscAPI:GetAllSocietyJobsFromSocietiesPlayerEmployedAtOrOwns(char:GetCharId())
    if jobs then
        return cb(jobs)
    else
        return cb(false)
    end
end)

RegisterServerEvent("bcc-society:UpdateJob", function(jobName, societyId)
    local _source = source
    local char = Core.getUser(_source)
    local society = SocietyAPI:GetSociety(societyId)
    if society then
        local employeeRank = society:GetEmployeeRank(char:GetCharId())
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
                char.setJob(jobName, grade)
                Core.NotifyRightTip(_source, _U("jobChanged"), 4000)
            end
        end
    end
end)

RegisterServerEvent("bcc-society:ToggleDuty", function()
    local _source = source
    local user = Core.getUser(_source)
    if not user then 
        return
    end

    local char = user.getUsedCharacter
    if not char then
        return
    end

    local charJob = char.job
    local charJobGrade = char.jobGrade
    local toggled = false

    -- Determine if the character is currently on or off duty based on job prefix
    if string.sub(charJob, 1, 3) == "off" then
        -- Switch to on-duty (remove "off" prefix)
        local onDutyJob = string.sub(charJob, 4)
        char.setJob(onDutyJob, charJobGrade)
        Core.NotifyRightTip(_source, _U("onDuty"), 4000)

        -- Update employee rank in the database to reflect on-duty
        MySQL.query.await("UPDATE bcc_society_employees SET employee_rank = ? WHERE employee_id = ?", { onDutyJob, char.charIdentifier })
        toggled = true

    else
        -- Switch to off-duty (add "off" prefix)
        local offDutyJob = "off" .. charJob
        char.setJob(offDutyJob, charJobGrade)
        Core.NotifyRightTip(_source, _U("offDuty"), 4000)

        -- Update employee rank in the database to reflect off-duty
        MySQL.query.await("UPDATE bcc_society_employees SET employee_rank = ? WHERE employee_id = ?", { offDutyJob, char.charIdentifier })
        toggled = true
    end

    if not toggled then
        Core.NotifyRightTip(_source, "no toggle occurred", 4000) -- Optional message if no toggle occurred
    end
end)

AddEventHandler('playerDropped', function(reason)
    local playerId = source
    local user = Core.getUser(playerId)
    if not user then 
        return
    end
    -- Make sure user exists and character is active
    if user then
        local char = user.getUsedCharacter
        if char then
            local charJob = char.job

            -- Check if the player is on duty (doesn't have "off" prefix)
            if string.sub(charJob, 1, 3) ~= "off" then
                -- Set the player off-duty in the database
                local offDutyJob = "off" .. charJob
                MySQL.query.await("UPDATE bcc_society_employees SET employee_rank = ? WHERE employee_id = ?", { offDutyJob, char.charIdentifier })
                
                -- Optionally, you can log this action or notify admins if needed
                print("Player " .. playerId .. " set to off-duty: " .. offDutyJob)
            end
        end
    end
end)
