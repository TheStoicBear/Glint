local lightStates = {}  -- [vehNetId] = { flood=bool, alley=bool, track=bool }

RegisterNetEvent('spotlights:updateState')
AddEventHandler('spotlights:updateState', function(vehNetId, flood, alley, track)
    -- if all off, drop; else store and broadcast
    if not flood and not alley and not track then
        lightStates[vehNetId] = nil
    else
        lightStates[vehNetId] = { flood = flood, alley = alley, track = track }
        TriggerClientEvent('spotlights:syncStates', -1, vehNetId, flood, alley, track)
    end
end)

RegisterNetEvent('spotlights:requestSync')
AddEventHandler('spotlights:requestSync', function()
    local src = source
    for vehNetId, state in pairs(lightStates) do
        TriggerClientEvent('spotlights:syncStates',
            src,
            vehNetId,
            state.flood,
            state.alley,
            state.track
        )
    end
end)
