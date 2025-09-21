local onCooldownBlips = {}
RegisterServerEvent("bcc-society:ServerSyncBlips", function(blipName, blipHash, blipVector3, blipSocietyId, delete)
    local _source = source
    local now = os.time()
    local shouldDelete = delete == true
    local desiredState = shouldDelete and "false" or "true"

    local stateResult = MySQL.query.await("SELECT show_blip FROM bcc_society WHERE business_id = ?", { blipSocietyId })
    local currentState = stateResult and stateResult[1] and stateResult[1].show_blip or nil

    -- Allow silent resyncs when the persisted state already matches the requested state
    if currentState == desiredState then
        TriggerClientEvent('bcc-society:ClientSyncBlips', -1, blipName, blipHash, blipVector3, blipSocietyId, shouldDelete)
        return
    end

    local lastToggle = onCooldownBlips[blipSocietyId]
    if not lastToggle or os.difftime(now, lastToggle) >= Config.toggleBlipCooldown then
        onCooldownBlips[blipSocietyId] = now
        TriggerClientEvent('bcc-society:ClientSyncBlips', -1, blipName, blipHash, blipVector3, blipSocietyId, shouldDelete)
        MySQL.query.await("UPDATE bcc_society SET show_blip = ? WHERE business_id = ?", { desiredState, blipSocietyId })
    else
        NotifyClient(_source, _U("blipCooldown"), "error", 4000)
    end
end)
