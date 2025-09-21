SocietyAPI = {} -- Setting global so we can use it in this script aswell
exports("getSocietyAPI", function()
    return SocietyAPI
end)

function SocietyAPI:GetSociety(societyId)
    local societyData = MySQL.query.await("SELECT * FROM bcc_society WHERE business_id = ?", { societyId })
    if #societyData > 0 then
        local society = {}
        society.id = societyData[1].business_id
        function society:GetSocietyEmployees()
            local employees = MySQL.query.await("SELECT * FROM bcc_society_employees WHERE business_id = ?", { self.id })
            if #employees > 0 then
                return employees
            else
                return false
            end
        end
        function society:GetSocietyInfo()
            local info = MySQL.query.await("SELECT * FROM bcc_society WHERE business_id = ?", { self.id })
            if #info > 0 then
                return info[1]
            else
                return false
            end
        end
        function society:GetSocietyOwnerCharacterId()
            local info = self.GetSocietyInfo(self)
            if info then
                return info.owner_id
            else
                return false
            end
        end
        function society:CheckRankPermissions(rankName)
            local retval = MySQL.query.await("SELECT * FROM bcc_society_ranks WHERE business_id = ? AND rank_name = ?", { self.id, rankName })
            if #retval > 0 then
                return retval[1]
            else
                return false
            end
        end
        function society:CheckIfCharacterIsEmployee(charId)
            local retval = MySQL.query.await("SELECT * FROM bcc_society_employees WHERE business_id = ? AND employee_id = ?", { self.id, charId })
            if #retval > 0 then
                return true
            else
                return false
            end
        end
        function society:GetEmployeeData(charId)
            local retval = MySQL.query.await("SELECT * FROM bcc_society_employees WHERE business_id = ? AND employee_id = ?", { self.id, charId })
            if #retval > 0 then
                return retval[1]
            else
                return false
            end
        end
        function society:GetEmployeeRank(charId)
            local retval = MySQL.query.await(
                "SELECT * FROM bcc_society_employees WHERE business_id = ? AND employee_id = ?",
                { self.id, charId }
            )

            if #retval > 0 then
                local storedRank = retval[1].employee_rank

                if storedRank and type(storedRank) == "string" and storedRank:sub(1, 3) == "off" then
                    return storedRank:sub(4), storedRank
                end

                return storedRank, storedRank
            end

            local socInfo = self.GetSocietyInfo(self)
            if socInfo and socInfo.owner_id == charId then
                return "owner", "owner"
            end

            return false
        end
        function society:GetRankInfo(rankName)
            local retval = MySQL.query.await("SELECT * FROM bcc_society_ranks WHERE business_id = ? AND rank_name = ?", { self.id, rankName })
            if #retval > 0 then
                return retval[1]
            else
                return false
            end
        end
        function society:GetAllRanks()
            local retval = MySQL.query.await("SELECT * FROM bcc_society_ranks WHERE business_id = ?", { self.id })
            if #retval > 0 then
                return retval
            else
                return false
            end
        end
        function society:GetLedgerAmount()
            local retval = MySQL.query.await("SELECT * FROM bcc_society WHERE business_id = ?", { self.id })
            if #retval > 0 then
                return retval[1].ledger
            else
                return false
            end
        end
        function society:GetSocietyTaxAmount()
            local retval = MySQL.query.await("SELECT * FROM bcc_society WHERE business_id = ?", { self.id })
            if #retval > 0 then
                return retval[1].tax_amount
            else
                return false
            end
        end
        function society:AddMoneyToLedger(amount)
            MySQL.query.await("UPDATE bcc_society SET ledger = ledger + ? WHERE business_id = ?", { amount, self.id })
        end
        function society:RemoveMoneyFromLedger(amount)
            MySQL.query.await("UPDATE bcc_society SET ledger = ledger - ? WHERE business_id = ?", { amount, self.id })
        end

        return society
    else
        return false
    end
end

function SocietyAPI:GetSocietyByJob(jobName)
    local societyData = MySQL.query.await("SELECT * FROM bcc_society WHERE society_job = ?", { jobName })
    if #societyData > 0 then
        return self:GetSociety(societyData[1].business_id)
    end
    return false
end

SocietyAPI.MiscAPI = {}
function SocietyAPI.MiscAPI:GetAllSocietiesCharOwns(charIdentifier)
    local retval = MySQL.query.await("SELECT * FROM bcc_society WHERE owner_id = ?", { charIdentifier })
    if #retval > 0 then
        return retval
    else
        return false
    end
end

function SocietyAPI.MiscAPI:GetAllSocietiesCharIsEmployedAt(charIdentifier)
    local retval = MySQL.query.await("SELECT * FROM bcc_society_employees WHERE employee_id = ?", { charIdentifier })
    if #retval > 0 then
        return retval
    else
        return false
    end
end

function SocietyAPI.MiscAPI:GetAllSocieties()
    local retval = MySQL.query.await("SELECT * FROM bcc_society")
    if #retval > 0 then
        return retval
    else
        return false
    end
end

function SocietyAPI.MiscAPI:GetAllSocietyJobsFromSocietiesPlayerEmployedAtOrOwns(charIdentifier)
    local employedSocs = self.GetAllSocietiesCharIsEmployedAt(self, charIdentifier) or {}
    local ownedSocs = self.GetAllSocietiesCharOwns(self, charIdentifier) or {}

    if (#employedSocs == 0 and #ownedSocs == 0) then
        return false
    end

    local jobs, seen = {}, {}

    local function sanitizeRank(rank)
        if type(rank) ~= 'string' then return nil end
        if rank:sub(1, 3) == 'off' then
            rank = rank:sub(4)
        end
        if rank == '' or rank == 'none' then
            return nil
        end
        return rank
    end

    local function addEntry(businessId, rankSuggestion)
        if not businessId or seen[businessId] then return end

        local society = SocietyAPI:GetSociety(businessId)
        if not society then return end

        local info = society:GetSocietyInfo()
        if not info then return end

        seen[businessId] = true

        local rankName = sanitizeRank(rankSuggestion)
        local societyJob = info.society_job
        if type(societyJob) ~= 'string' or societyJob == '' or societyJob == 'none' then
            societyJob = nil
        end

        local jobName = rankName or societyJob or info.business_name
        local labelSuffix = rankName or societyJob

        local displayName = info.business_name
        if labelSuffix and labelSuffix ~= '' then
            displayName = string.format('%s (%s)', info.business_name, labelSuffix)
        end

        local rankEntries = {}
        local societyRanks = society:GetAllRanks()
        if societyRanks then
            for _, rankData in ipairs(societyRanks) do
                local canSwitch = tostring(rankData.rank_can_switch_job or "false"):lower() == "true"
                if canSwitch then
                    local rankLabel = rankData.rank_label
                    if not rankLabel or rankLabel == '' or rankLabel == 'none' then
                        rankLabel = rankData.rank_name
                    end

                    table.insert(rankEntries, {
                        rankName = rankData.rank_name,
                        rankLabel = rankLabel,
                        displayName = string.format('%s (%s)', info.business_name, rankLabel),
                        jobName = rankData.rank_name,
                        jobGrade = tonumber(rankData.society_job_rank) or 0,
                        canSwitch = true
                    })
                end
            end

            table.sort(rankEntries, function(a, b)
                return a.jobGrade < b.jobGrade
            end)
        end

        table.insert(jobs, {
            societyId = info.business_id,
            jobName = jobName,
            displayName = displayName,
            businessName = info.business_name,
            societyJob = societyJob,
            rankName = rankName,
            ranks = rankEntries
        })
    end

    for _, employment in ipairs(employedSocs) do
        addEntry(employment.business_id, employment.employee_rank)
    end

    for _, owned in ipairs(ownedSocs) do
        addEntry(owned.business_id, nil)
    end

    if #jobs == 0 then
        return false
    end

    table.sort(jobs, function(a, b)
        return a.displayName < b.displayName
    end)

    return jobs
end

function SocietyAPI.MiscAPI:CheckIfPlayerHasJobAndIsOnDuty(jobName, playerSource)
    if not (jobName and playerSource) then
        return false
    end

    local Character = Core.getUser(playerSource).getUsedCharacter
    if not Character then
        return false
    end

    local playerJob = Character.job
    local jobGrade = Character.jobGrade

    local employmentData = MySQL.query.await("SELECT employee_rank FROM bcc_society_employees WHERE employee_id = ?", { Character.charIdentifier })
    
    if not employmentData or #employmentData == 0 then
        return false
    end

    if playerJob == jobName then
        return true
    elseif playerJob == ("off" .. jobName) then
        return false
    end

    return false
end
