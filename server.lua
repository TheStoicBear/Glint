local lightStates = {}  -- [vehNetId] = { flood=bool, alley=bool, track=bool }

RegisterNetEvent('spotlights:updateState')
AddEventHandler('spotlights:updateState', function(vehNetId, flood, alley, track)
    if not flood and not alley and not track then
        lightStates[vehNetId] = nil
    else
        lightStates[vehNetId] = { flood = flood, alley = alley, track = track }
    end
    -- broadcast this change to everyone
    TriggerClientEvent('spotlights:syncStates', -1, vehNetId, flood, alley, track)
end)

RegisterNetEvent('spotlights:requestSync')
AddEventHandler('spotlights:requestSync', function()
    local src = source
    for vehNetId, st in pairs(lightStates) do
        TriggerClientEvent(
          'spotlights:syncStates',
          src,
          vehNetId,
          st.flood,
          st.alley,
          st.track
        )
    end
end)
