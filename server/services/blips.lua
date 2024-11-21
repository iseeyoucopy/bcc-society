local onCooldownBlips = {}
RegisterServerEvent("bcc-society:ServerSyncBlips", function(blipName, blipHash, blipVector3, blipSocietyId, delete)
    local _source = source
    if not onCooldownBlips[blipSocietyId] then
        TriggerClientEvent('bcc-society:ClientSyncBlips', -1, blipName, blipHash, blipVector3, blipSocietyId, delete)
        onCooldownBlips[blipSocietyId] = os.time()
        if delete then delete = "false" end
        if not delete then delete = "true" end
        MySQL.query.await("UPDATE bcc_society SET show_blip = ? WHERE business_id = ?", { delete, blipSocietyId })
    elseif onCooldownBlips[blipSocietyId] and os.difftime(os.time(), onCooldownBlips[blipSocietyId]) >= Config.toggleBlipCooldown then
        onCooldownBlips[blipSocietyId] = os.time()
        TriggerClientEvent('bcc-society:ClientSyncBlips', -1, blipName, blipHash, blipVector3, blipSocietyId, delete)
        if delete then delete = "false" end
        if not delete then delete = "true" end
        MySQL.query.await("UPDATE bcc_society SET show_blip = ? WHERE business_id = ?", { delete, blipSocietyId })
    else
        Core:NotifyRightTip(_source, _U("blipCooldown"), 4000)
    end
end)