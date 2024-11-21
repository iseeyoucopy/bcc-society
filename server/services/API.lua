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
            local retval = MySQL.query.await("SELECT * FROM bcc_society_employees WHERE business_id = ? AND employee_id = ?", { self.id, charId })
            if #retval > 0 then
                return retval[1].employee_rank
            else
                local socInfo = self.GetSocietyInfo(self)
                if socInfo and socInfo.owner_id == charId then
                    return "owner"
                else
                    return false
                end
            end
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
    local allEmployedSocs = self.GetAllSocietiesCharIsEmployedAt(self, charIdentifier)
    local ownedSocs = self.GetAllSocietiesCharOwns(self, charIdentifier)
    if allEmployedSocs or ownedSocs then
        local jobs = {}
        if allEmployedSocs then
            for k, v in pairs(allEmployedSocs) do
                local socInfo = SocietyAPI:GetSociety(v.business_id):GetSocietyInfo()
                if socInfo and socInfo.society_job ~= "none" then
                    table.insert(jobs, {jobName = socInfo.society_job, societyId = v.business_id})
                else
                    table.remove(allEmployedSocs, k)
                end
            end
        end
        if ownedSocs then
            for k, v in pairs(ownedSocs) do
                if #jobs > 0 then
                    for e, a in pairs(jobs) do
                        if a ~= v.society_job and v.society_job ~= "none" then
                            table.insert(jobs, {jobName = v.society_job, societyId = v.business_id}) break
                        else
                            table.remove(ownedSocs, k)
                        end
                    end
                else
                    if v.society_job ~= 'none' then
                        table.insert(jobs, {jobName = v.society_job, societyId = v.business_id})
                    else
                        table.remove(ownedSocs, k)
                    end
                end
            end
        end
        if #jobs > 0 then
            return jobs
        else
            return false
        end
    else
        return false
    end
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

    if #Config.onDutyJobs > 0 then
        for _, onDutyJob in pairs(Config.onDutyJobs) do
            if playerJob == jobName then
                return true
            elseif playerJob == ("off" .. jobName) then
                return false
            end
        end
    end

    return false
end
