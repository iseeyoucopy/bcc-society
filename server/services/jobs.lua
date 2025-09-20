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

local function stripOffPrefix(value)
    if type(value) ~= "string" then
        return value, false
    end

    if value:sub(1, 3) == "off" then
        return value:sub(4), true
    end

    return value, false
end

local function findSocietyByIdentifier(charIdentifier, identifier, employments, ownedSocieties)
    if type(identifier) ~= "string" or identifier == "" then
        return nil
    end

    local identLower = identifier:lower()
    local numericId = tonumber(identifier)

    employments = employments or SocietyAPI.MiscAPI:GetAllSocietiesCharIsEmployedAt(charIdentifier)
    if employments then
        for _, employment in ipairs(employments) do
            if numericId and employment.business_id == numericId then
                return SocietyAPI:GetSociety(employment.business_id)
            end

            local cleanRank = stripOffPrefix(employment.employee_rank)
            if type(cleanRank) == "string" then
                local lowerRank = cleanRank:lower()
                if lowerRank == identLower or ("off" .. lowerRank) == identLower then
                    return SocietyAPI:GetSociety(employment.business_id)
                end
            end

            local society = SocietyAPI:GetSociety(employment.business_id)
            if society then
                local info = society:GetSocietyInfo()
                if info then
                    if type(info.society_job) == "string" and info.society_job:lower() == identLower then
                        return society
                    end
                    if type(info.business_name) == "string" and info.business_name:lower() == identLower then
                        return society
                    end
                end
            end
        end
    end

    ownedSocieties = ownedSocieties or SocietyAPI.MiscAPI:GetAllSocietiesCharOwns(charIdentifier)
    if ownedSocieties then
        for _, info in ipairs(ownedSocieties) do
            if numericId and info.business_id == numericId then
                return SocietyAPI:GetSociety(info.business_id)
            end
            if type(info.society_job) == "string" and info.society_job:lower() == identLower then
                return SocietyAPI:GetSociety(info.business_id)
            end
            if type(info.business_name) == "string" and info.business_name:lower() == identLower then
                return SocietyAPI:GetSociety(info.business_id)
            end
        end
    end

    return nil
end

local function determineActiveJobName(society, character, employeeRank)
    if not society or not character then
        return nil
    end

    local rankName = employeeRank
    if type(rankName) ~= "string" or rankName == "" or rankName == "none" then
        rankName = nil
    end

    local societyInfo = society:GetSocietyInfo()
    local societyJob = societyInfo and societyInfo.society_job or nil
    if type(societyJob) ~= "string" or societyJob == "" or societyJob == "none" then
        societyJob = nil
    end

    if employeeRank == "owner" then
        return societyJob or "owner"
    end

    if rankName then
        return rankName
    end

    if societyInfo and societyInfo.owner_id == character.charIdentifier then
        return societyJob or "owner"
    end

    return societyJob
end

local function resolveSocietyRank(society, rankInput, character)
    if not society or type(rankInput) ~= "string" then
        return nil, nil, "invalid"
    end

    local trimmed = rankInput:match("^%s*(.-)%s*$")
    if not trimmed or trimmed == "" then
        return nil, nil, "invalid"
    end

    local lower = trimmed:lower()
    local ownerId = society:GetSocietyOwnerCharacterId()
    local charIdentifier = character and character.charIdentifier or nil
    local charIsOwner = ownerId and charIdentifier and ownerId == charIdentifier

    local function evaluate(rankRow)
        if not rankRow then
            return nil, nil, "notFound"
        end
        local canSwitch = tostring(rankRow.rank_can_switch_job or "false"):lower()
        if canSwitch == "true" or charIsOwner then
            return rankRow.rank_name, rankRow, "ok"
        end
        return nil, nil, "noPermission"
    end

    local name, info, reason = evaluate(society:GetRankInfo(trimmed))
    if name then
        devPrint(string.format("[resolveSocietyRank] Matched exact rank '%s' for society %s", name, tostring(society.id)))
        return name, info, reason
    elseif reason == "noPermission" then
        devPrint(string.format("[resolveSocietyRank] Rank '%s' found but lacks switch permission", trimmed))
        return nil, nil, reason
    end

    local allRanks = society:GetAllRanks()
    if allRanks then
        for _, rankData in ipairs(allRanks) do
            if type(rankData.rank_name) == "string" and rankData.rank_name:lower() == lower then
                local n, i, r = evaluate(rankData)
                if n then
                    devPrint(string.format("[resolveSocietyRank] Matched rank by case-insensitive name '%s' for society %s", n, tostring(society.id)))
                    return n, i, r
                else
                    devPrint(string.format("[resolveSocietyRank] Rank '%s' found but lacks switch permission", rankData.rank_name))
                    return nil, nil, r
                end
            end
            if type(rankData.rank_label) == "string" and rankData.rank_label ~= "none" and rankData.rank_label:lower() == lower then
                local n, i, r = evaluate(rankData)
                if n then
                    devPrint(string.format("[resolveSocietyRank] Matched rank by label '%s' for society %s", n, tostring(society.id)))
                    return n, i, r
                else
                    devPrint(string.format("[resolveSocietyRank] Rank label '%s' found but lacks switch permission", rankData.rank_label))
                    return nil, nil, r
                end
            end
        end
    end

    devPrint(string.format("[resolveSocietyRank] Could not resolve '%s' for society %s", trimmed, tostring(society.id)))
    return nil, nil, "notFound"
end

local function markSocietyDutyState(character, activeSocietyId)
    if not character then return end

    local charIdentifier = character.charIdentifier
    if not charIdentifier then return end

    local employedSocieties = SocietyAPI.MiscAPI:GetAllSocietiesCharIsEmployedAt(charIdentifier)
    if not employedSocieties then return end

    for _, employment in ipairs(employedSocieties) do
        local society = SocietyAPI:GetSociety(employment.business_id)
        if society then
            local cleanRank = employment.employee_rank
            if type(cleanRank) == "string" then
                cleanRank = select(1, stripOffPrefix(cleanRank))
            else
                cleanRank = nil
            end

            local desiredValue
            local preferred = determineActiveJobName(society, character, cleanRank)

            if employment.business_id == activeSocietyId then
                desiredValue = preferred or cleanRank
            else
                local base = preferred or cleanRank
                if base then
                    desiredValue = "off" .. base
                end
            end

            if desiredValue and employment.employee_rank ~= desiredValue then
                MySQL.query.await(
                    "UPDATE bcc_society_employees SET employee_rank = ? WHERE business_id = ? AND employee_id = ?",
                    { desiredValue, employment.business_id, charIdentifier }
                )
            end
        end
    end
end

local function resolveJobGrade(society, character, employeeRank)
    if employeeRank == "owner" or society:GetSocietyOwnerCharacterId() == character.charIdentifier then
        local info = society:GetSocietyInfo()
        if info and info.max_job_grade then
            return tonumber(info.max_job_grade) or 0
        end
        return 0
    end

    if not employeeRank or employeeRank == "" or employeeRank == "none" then
        return 0
    end

    local rankInfo = society:GetRankInfo(employeeRank)
    if rankInfo and rankInfo.society_job_rank then
        return tonumber(rankInfo.society_job_rank) or 0
    end

    return 0
end

local function setActiveSocietyJob(src, character, society)
    if not society then
        NotifyClient(src, _U("noRankSetCanNotSwitchJob"), "error", 4000)
        devPrint(string.format("[setActiveSocietyJob] Society not found for char %s", tostring(character and character.charIdentifier)))
        return false
    end

    local employeeRank = society:GetEmployeeRank(character.charIdentifier)
    if not employeeRank then
        NotifyClient(src, _U("noRankSetCanNotSwitchJob"), "error", 4000)
        devPrint(string.format("[setActiveSocietyJob] No employee rank for char %s in society %s", tostring(character.charIdentifier), tostring(society.id)))
        return false
    end

    local activeJobName = determineActiveJobName(society, character, employeeRank)

    if type(activeJobName) ~= "string" or activeJobName == "" or activeJobName == "none" then
        NotifyClient(src, _U("noRankSetCanNotSwitchJob"), "error", 4000)
        devPrint(string.format("[setActiveSocietyJob] Active job invalid for char %s (rank %s)", tostring(character.charIdentifier), tostring(employeeRank)))
        return false
    end

    local grade = resolveJobGrade(society, character, employeeRank)

    markSocietyDutyState(character, society.id)

    character.setJob(activeJobName)
    character.setJobGrade(grade)
    devPrint(string.format("[setActiveSocietyJob] Char %s now job '%s' grade %s (society %s rank %s)", tostring(character.charIdentifier), activeJobName, tostring(grade), tostring(society.id), tostring(employeeRank)))

    return true
end

local jobSwitchCooldowns = {}

RegisterServerEvent("bcc-society:UpdateJob", function(jobName, societyId, desiredRank)
    local src = source
    local user = Core.getUser(src)
    if not user then return end

    local character = user.getUsedCharacter
    if not character then return end

    devPrint(string.format("[UpdateJob] char %s requested job '%s' society %s desiredRank '%s'", tostring(character.charIdentifier), tostring(jobName), tostring(societyId), tostring(desiredRank)))

    if (not societyId or societyId == 0) and (not jobName or jobName == "" or jobName == "none") then
        NotifyClient(src, _U("switchJobNotFound"), "error", 4000)
        return
    end

    local society = societyId and SocietyAPI:GetSociety(societyId) or nil
    if not society and jobName and jobName ~= "" and jobName ~= "none" then
        society = SocietyAPI:GetSocietyByJob(jobName)
    end
    if not society then
        NotifyClient(src, _U("switchJobNotFound"), "error", 4000)
        return
    end

    local requestedRankName, _, rankResolutionReason
    if desiredRank then
        requestedRankName, _, rankResolutionReason = resolveSocietyRank(society, desiredRank, character)
        if not requestedRankName and rankResolutionReason == "noPermission" then
            NotifyClient(src, _U("rankNoSwitchPermission"), "error", 4000)
            devPrint(string.format("[UpdateJob] Rank '%s' lacks permission to switch for char %s", tostring(desiredRank), tostring(character.charIdentifier)))
            return
        end
    end

    if (not requestedRankName) and jobName and jobName ~= '' and jobName ~= 'none' then
        local fallbackName, _, fallbackReason = resolveSocietyRank(society, jobName, character)
        if fallbackName then
            requestedRankName = fallbackName
        elseif fallbackReason == "noPermission" then
            NotifyClient(src, _U("rankNoSwitchPermission"), "error", 4000)
            devPrint(string.format("[UpdateJob] Fallback rank '%s' lacks permission for char %s", tostring(jobName), tostring(character.charIdentifier)))
            return
        end
    end

    if requestedRankName then
        local employeeData = society:GetEmployeeData(character.charIdentifier)
        local isOwner = society:GetSocietyOwnerCharacterId() == character.charIdentifier

        if employeeData then
            devPrint(string.format("[UpdateJob] Setting rank '%s' for char %s in society %s", requestedRankName, tostring(character.charIdentifier), tostring(society.id)))
            MySQL.query.await(
                "UPDATE bcc_society_employees SET employee_rank = ? WHERE business_id = ? AND employee_id = ?",
                { requestedRankName, society.id, character.charIdentifier }
            )
        elseif isOwner then
            local fullName = string.format('%s %s', character.firstname or 'Unknown', character.lastname or 'Unknown')
            devPrint(string.format("[UpdateJob] Owner char %s assigned self rank '%s' for society %s", tostring(character.charIdentifier), requestedRankName, tostring(society.id)))
            MySQL.query.await(
                "INSERT INTO bcc_society_employees (employee_id, business_id, employee_name, employee_rank) VALUES (?, ?, ?, ?)",
                { character.charIdentifier, society.id, fullName, requestedRankName }
            )
        else
            NotifyClient(src, _U("noRankSetCanNotSwitchJob"), "error", 4000)
            devPrint(string.format("[UpdateJob] Unable to set rank '%s' for char %s - not employee/owner", requestedRankName, tostring(character.charIdentifier)))
            return
        end
    end

    if setActiveSocietyJob(src, character, society) then
        NotifyClient(src, _U("jobChanged"), "success", 4000)
    end
end)

-- Toggle ON Duty Event
RegisterServerEvent("bcc-society:ToggleOnDuty", function()
    local src = source
    local user = Core.getUser(src)
    if not user then return end

    local character = user.getUsedCharacter
    if not character then return end

    local charJob = character.job
    if not charJob or type(charJob) ~= "string" then
        NotifyClient(src, _U("noRankSetCanNotSwitchJob"), "error", 4000)
        return
    end

    local jobName, wasOff = stripOffPrefix(charJob)
    if not wasOff or not jobName or jobName == "" then
        NotifyClient(src, "You are already on duty!", "error", 4000)
        return
    end

    local employments = SocietyAPI.MiscAPI:GetAllSocietiesCharIsEmployedAt(character.charIdentifier)
    local ownedSocieties = SocietyAPI.MiscAPI:GetAllSocietiesCharOwns(character.charIdentifier)
    local hasEmployment = type(employments) == "table" and #employments > 0
    local hasOwned = type(ownedSocieties) == "table" and #ownedSocieties > 0

    local society = findSocietyByIdentifier(character.charIdentifier, jobName, employments, ownedSocieties)
    if not society then
        if not hasEmployment and not hasOwned then
            NotifyClient(src, "You are not employed in a society and cannot toggle duty status.", "error", 4000)
        else
            NotifyClient(src, _U("switchJobNotFound"), "error", 4000)
        end
        return
    end

    if setActiveSocietyJob(src, character, society) then
        NotifyClient(src, _U("onDuty"), "success", 4000)
    end
end)

RegisterServerEvent("bcc-society:ToggleOffDuty", function()
    local src = source
    local user = Core.getUser(src)
    if not user then return end

    local character = user.getUsedCharacter
    if not character then return end

    local charJob = character.job
    if not charJob or type(charJob) ~= "string" then
        NotifyClient(src, _U("noRankSetCanNotSwitchJob"), "error", 4000)
        return
    end

    local jobName, isOff = stripOffPrefix(charJob)
    if isOff then
        NotifyClient(src, "You are already off duty!", "error", 4000)
        return
    end

    if not jobName or jobName == "" then
        NotifyClient(src, _U("noRankSetCanNotSwitchJob"), "error", 4000)
        return
    end

    local employments = SocietyAPI.MiscAPI:GetAllSocietiesCharIsEmployedAt(character.charIdentifier)
    local ownedSocieties = SocietyAPI.MiscAPI:GetAllSocietiesCharOwns(character.charIdentifier)
    local hasEmployment = type(employments) == "table" and #employments > 0
    local hasOwned = type(ownedSocieties) == "table" and #ownedSocieties > 0

    local society = findSocietyByIdentifier(character.charIdentifier, jobName, employments, ownedSocieties)
    if not society then
        if not hasEmployment and not hasOwned then
            NotifyClient(src, "You are not employed in a society and cannot toggle duty status.", "error", 4000)
        else
            NotifyClient(src, _U("switchJobNotFound"), "error", 4000)
        end
        return
    end

    local employeeData = society:GetEmployeeData(character.charIdentifier)
    local cleanRank
    if employeeData and employeeData.employee_rank then
        cleanRank = select(1, stripOffPrefix(employeeData.employee_rank))
        if cleanRank then
            local desiredOff = determineActiveJobName(society, character, cleanRank) or cleanRank or jobName
            MySQL.query.await(
                "UPDATE bcc_society_employees SET employee_rank = ? WHERE business_id = ? AND employee_id = ?",
                { "off" .. desiredOff, society.id, character.charIdentifier }
            )
        end
    end

    local activeBase = determineActiveJobName(society, character, cleanRank or society:GetEmployeeRank(character.charIdentifier)) or cleanRank or jobName
    if not activeBase or activeBase == '' or activeBase == 'none' then
        NotifyClient(src, _U("noRankSetCanNotSwitchJob"), "error", 4000)
        return
    end

    local offDutyJob = "off" .. activeBase
    character.setJob(offDutyJob)
    NotifyClient(src, _U("offDuty"), "success", 4000)
end)

RegisterServerEvent("bcc-society:SwitchJobCommand", function(rawIdentifier)
    local src = source
    local user = Core.getUser(src)
    if not user then return end

    local character = user.getUsedCharacter
    if not character then return end

    devPrint(string.format("[SwitchJobCommand] char %s input '%s'", tostring(character.charIdentifier), tostring(rawIdentifier)))

    if type(rawIdentifier) ~= "string" then
        NotifyClient(src, _U("switchJobUsage"), "error", 4000)
        return
    end

    local identifier = rawIdentifier:match("^%s*(.-)%s*$")
    if not identifier or identifier == "" then
        NotifyClient(src, _U("switchJobUsage"), "error", 4000)
        return
    end

    local cooldownSeconds = tonumber(Config.switchJobCooldownSeconds) or 0
    local now = os.time()

    if cooldownSeconds > 0 then
        local lastSwitch = jobSwitchCooldowns[character.charIdentifier] or 0
        local remaining = cooldownSeconds - (now - lastSwitch)
        if remaining > 0 then
            NotifyClient(src, string.format(_U("switchJobCooldown"), remaining), "error", 4000)
            return
        end
    end

    local employments = SocietyAPI.MiscAPI:GetAllSocietiesCharIsEmployedAt(character.charIdentifier)
    local ownedSocieties = SocietyAPI.MiscAPI:GetAllSocietiesCharOwns(character.charIdentifier)
    local hasEmployment = type(employments) == "table" and #employments > 0
    local hasOwned = type(ownedSocieties) == "table" and #ownedSocieties > 0

    if not hasEmployment and not hasOwned then
        NotifyClient(src, _U("switchJobNoEmployment"), "error", 4000)
        return
    end

    local society = findSocietyByIdentifier(character.charIdentifier, identifier, employments, ownedSocieties)
    if not society then
        NotifyClient(src, _U("switchJobNotFound"), "error", 4000)
        return
    end

    local resolvedRankName = nil
    local employeeData = society:GetEmployeeData(character.charIdentifier)
    local isOwner = society:GetSocietyOwnerCharacterId() == character.charIdentifier

    local rankNameCandidate, _, candidateReason = resolveSocietyRank(society, identifier, character)
    if rankNameCandidate then
        resolvedRankName = rankNameCandidate

        if employeeData then
            devPrint(string.format("[SwitchJobCommand] Updating rank to '%s' for char %s in society %s", resolvedRankName, tostring(character.charIdentifier), tostring(society.id)))
            MySQL.query.await(
                "UPDATE bcc_society_employees SET employee_rank = ? WHERE business_id = ? AND employee_id = ?",
                { resolvedRankName, society.id, character.charIdentifier }
            )
        elseif isOwner then
            local fullName = string.format('%s %s', character.firstname or 'Unknown', character.lastname or 'Unknown')
            devPrint(string.format("[SwitchJobCommand] Owner char %s inserting rank '%s' for society %s", tostring(character.charIdentifier), resolvedRankName, tostring(society.id)))
            MySQL.query.await(
                "INSERT INTO bcc_society_employees (employee_id, business_id, employee_name, employee_rank) VALUES (?, ?, ?, ?)",
                { character.charIdentifier, society.id, fullName, resolvedRankName }
            )
        else
            NotifyClient(src, _U("noRankSetCanNotSwitchJob"), "error", 4000)
            devPrint(string.format("[SwitchJobCommand] Char %s not employee/owner cannot switch rank '%s'", tostring(character.charIdentifier), resolvedRankName))
            return
        end
    elseif candidateReason == "noPermission" then
        NotifyClient(src, _U("rankNoSwitchPermission"), "error", 4000)
        devPrint(string.format("[SwitchJobCommand] Rank '%s' lacks permission for char %s", identifier, tostring(character.charIdentifier)))
        return
    elseif candidateReason == "invalid" then
        devPrint(string.format("[SwitchJobCommand] Invalid rank input '%s'", identifier))
    end

    if setActiveSocietyJob(src, character, society) then
        NotifyClient(src, _U("jobChanged"), "success", 4000)
        if cooldownSeconds > 0 then
            jobSwitchCooldowns[character.charIdentifier] = now
        end
    end
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

-- Player Disconnect Handler: set on-duty employees to off-duty
AddEventHandler('playerDropped', function(_)
    local src = source
    if not src then return end

    local user = Core.getUser(src)
    if not user then return end
    local character = user.getUsedCharacter
    if not character then return end

    local charJob = character.job
    if not charJob or type(charJob) ~= "string" then return end

    local jobName, isOff = stripOffPrefix(charJob)
    if not jobName or jobName == "" then return end

    local employments = SocietyAPI.MiscAPI:GetAllSocietiesCharIsEmployedAt(character.charIdentifier)
    local ownedSocieties = SocietyAPI.MiscAPI:GetAllSocietiesCharOwns(character.charIdentifier)

    local society = findSocietyByIdentifier(character.charIdentifier, jobName, employments, ownedSocieties)
    if not society then return end

    local employeeData = society:GetEmployeeData(character.charIdentifier)
    local cleanRank
    if employeeData and employeeData.employee_rank then
        cleanRank = select(1, stripOffPrefix(employeeData.employee_rank))
        if cleanRank then
            local desiredOff = determineActiveJobName(society, character, cleanRank) or cleanRank or jobName
            MySQL.query.await(
                "UPDATE bcc_society_employees SET employee_rank = ? WHERE business_id = ? AND employee_id = ?",
                { "off" .. desiredOff, society.id, character.charIdentifier }
            )
        end
    end

    if not isOff then
        local offBase = determineActiveJobName(society, character, cleanRank or society:GetEmployeeRank(character.charIdentifier)) or jobName
        if offBase then
            character.setJob("off" .. offBase)
        end
    end
end)
