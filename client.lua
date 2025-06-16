-- Store last vehicle and light states
local lastVehicle         = nil
local floodlightsOn       = false
local alleyLightsOn       = false
local trackMode           = false
local trackedVehicle      = nil
local lastLTime           = 0
local doubleTapThreshold  = 300    -- ms for single/double tap
local uiVisible           = false
local uiFocused           = false
local remoteStates        = {}     -- [ vehNetId ] = { flood, alley, track }
local rotationSmoothFactor= 0.15
local currentTrackDir     = vector3(1.0, 0.0, 0.0)
local trackMaxDistance    = 250.0
local trackAngleThreshold = math.cos(math.rad(90))
local isOutOfVehicle      = true   -- Tracks if the player is out of vehicle

-- send our current state to the server
local function sendMyState()
    if lastVehicle and DoesEntityExist(lastVehicle) then
        TriggerServerEvent(
          'spotlights:updateState',
          VehToNet(lastVehicle),
          floodlightsOn,
          alleyLightsOn,
          trackMode
        )
    end
end

-- Acquire first valid target ahead (unchanged)
local function AcquireTarget()
    local ped     = PlayerPedId()
    local pos     = GetEntityCoords(ped)
    local forward = GetEntityForwardVector(ped)
    local start   = pos + forward * 1.0
    local finish  = pos + forward * trackMaxDistance
    local ray     = StartShapeTestRay(start.x, start.y, start.z, finish.x, finish.y, finish.z, 10, ped, 0)
    local _, _, _, _, entity = GetShapeTestResult(ray)
    if entity and IsEntityAVehicle(entity) then
        local tpos = GetEntityCoords(entity)
        local dir  = tpos - pos
        local dist = #dir
        if dist <= trackMaxDistance then
            local dirNorm = dir / dist
            local dot     = forward.x * dirNorm.x + forward.y * dirNorm.y + forward.z * dirNorm.z
            if dot >= trackAngleThreshold then
                return entity
            end
        end
    end
    return nil
end

-- Commands to toggle UI and focus
RegisterCommand('spotlightui', function()
    uiVisible = not uiVisible
    if uiVisible then
        uiFocused = true
        SetNuiFocus(true, true)
        SendNUIMessage({
          action = 'open',
          flood  = floodlightsOn,
          alley  = alleyLightsOn,
          track  = trackMode,
        })
        SendNUIMessage({ action = 'focus', focus = true })
    else
        uiFocused = false
        SetNuiFocus(false, false)
        SendNUIMessage({ action = 'close' })
        SendNUIMessage({ action = 'focus', focus = false })
    end
end, false)

-- UI callbacks: original logic + sendMyState()
RegisterNUICallback('toggleFlood', function(data, cb)
    floodlightsOn = not floodlightsOn
    alleyLightsOn, trackMode, trackedVehicle = false, false, nil
    SendNUIMessage({
      action = 'update',
      flood  = floodlightsOn,
      alley  = alleyLightsOn,
      track  = trackMode,
    })
    sendMyState()
    cb('ok')
end)

RegisterNUICallback('toggleAlley', function(data, cb)
    alleyLightsOn = not alleyLightsOn
    floodlightsOn, trackMode, trackedVehicle = false, false, nil
    SendNUIMessage({
      action = 'update',
      flood  = floodlightsOn,
      alley  = alleyLightsOn,
      track  = trackMode,
    })
    sendMyState()
    cb('ok')
end)

RegisterNUICallback('toggleTrack', function(data, cb)
    trackMode = not trackMode
    floodlightsOn, alleyLightsOn = trackMode, false
    trackedVehicle = nil
    SendNUIMessage({
      action = 'update',
      flood  = floodlightsOn,
      alley  = alleyLightsOn,
      track  = trackMode,
    })
    sendMyState()
    cb('ok')
end)

RegisterNUICallback('toggleAll', function(data, cb)
    local anyOn = floodlightsOn or alleyLightsOn or trackMode
    floodlightsOn  = not anyOn
    alleyLightsOn  = not anyOn
    trackMode      = not anyOn
    trackedVehicle = nil
    SendNUIMessage({
      action = 'update',
      flood  = floodlightsOn,
      alley  = alleyLightsOn,
      track  = trackMode,
    })
    sendMyState()
    cb('ok')
end)

RegisterNUICallback('closeUI', function(data, cb)
    uiVisible, uiFocused = false, false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'close' })
    cb('ok')
end)

RegisterNUICallback('escape', function(data, cb)
    if uiFocused then
        SetNuiFocus(false, false)
        uiFocused = false
        SendNUIMessage({ action = 'focus', focus = false })
    end
    cb('ok')
end)

-- L key single/double tap for flood/alley (unchanged + sendMyState)
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if IsControlJustReleased(0, 100) then -- [ key
            local now = GetGameTimer()
            if now - lastLTime < doubleTapThreshold then
                alleyLightsOn = not alleyLightsOn
                if alleyLightsOn then
                    floodlightsOn, trackMode, trackedVehicle = false, false, nil
                end
            else
                floodlightsOn = not floodlightsOn
                if floodlightsOn then
                    alleyLightsOn = false
                end
            end
            lastLTime = now
            sendMyState()
            if uiVisible then
                SendNUIMessage({
                  action = 'update',
                  flood  = floodlightsOn,
                  alley  = alleyLightsOn,
                  track  = trackMode,
                })
            end
        end
    end
end)

-- Main render loop (unchanged)
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        local ped = PlayerPedId()
        if IsPedInAnyVehicle(ped, false) then
            isOutOfVehicle = false
            lastVehicle    = GetVehiclePedIsIn(ped, false)
        else
            isOutOfVehicle = true
        end

        local veh = (not isOutOfVehicle and GetVehiclePedIsIn(ped, false)) or lastVehicle

        if veh and DoesEntityExist(veh) then
            if not isOutOfVehicle or (isOutOfVehicle and (floodlightsOn or alleyLightsOn or trackMode)) then
                -- Floodlights
                if floodlightsOn then
                    local positions = {
                        vector3(0.0, 1.5, 1.5),
                        vector3(-0.8, 1.5, 1.5),
                        vector3(0.8, 1.5, 1.5),
                    }
                    local fwd = GetEntityForwardVector(veh)
                    for _, pos in ipairs(positions) do
                        local worldPos = GetOffsetFromEntityInWorldCoords(veh, pos.x, pos.y, pos.z)
                        DrawSpotLight(
                          worldPos.x, worldPos.y, worldPos.z,
                          fwd.x, fwd.y, 0.0,
                          255,255,255, 40.0,40.0,10.0,50.0,40.0
                        )
                    end
                end

                -- Alley lights
                if alleyLightsOn then
                    local posR = GetOffsetFromEntityInWorldCoords(veh, 0.8, 0.0, 1.5)
                    local posL = GetOffsetFromEntityInWorldCoords(veh, -0.8, 0.0, 1.5)
                    local fwd  = GetEntityForwardVector(veh)
                    local fwdXY= vector3(fwd.x, fwd.y, 0.0)
                    local mag  = math.sqrt(fwdXY.x^2 + fwdXY.y^2) or 1.0
                    fwdXY = fwdXY / mag
                    local right = vector3(fwdXY.y, -fwdXY.x, -0.1)
                    local left  = vector3(-fwdXY.y, fwdXY.x, -0.1)
                    DrawSpotLight(
                      posR.x, posR.y, posR.z,
                      right.x, right.y, right.z,
                      255,255,255, 30.0,20.0,1.0,35.0,5.0
                    )
                    DrawSpotLight(
                      posL.x, posL.y, posL.z,
                      left.x, left.y, left.z,
                      255,255,255, 30.0,20.0,1.0,35.0,5.0
                    )
                end

                -- Track light
                if trackMode then
                    if not trackedVehicle then
                        trackedVehicle = AcquireTarget()
                    end
                    local pos = GetOffsetFromEntityInWorldCoords(veh, 0.8, 0.7, 1.5)
                    local desired = trackedVehicle and DoesEntityExist(trackedVehicle)
                      and (GetEntityCoords(trackedVehicle) - pos)
                      or GetEntityForwardVector(veh)
                    desired = vector3(desired.x, desired.y, 0.0)
                    local mag = math.sqrt(desired.x^2 + desired.y^2) or 1.0
                    desired = desired / mag
                    currentTrackDir = currentTrackDir +
                      (desired - currentTrackDir) * rotationSmoothFactor

                    DrawSpotLight(
                      pos.x, pos.y, pos.z,
                      currentTrackDir.x,
                      currentTrackDir.y,
                      0.0,
                      221,221,221, 50.0,30.0,4.3,25.0,28.6
                    )
                end
            end
        end
    end
end)

-- Handle incoming state sync from server
RegisterNetEvent('spotlights:syncStates')
AddEventHandler('spotlights:syncStates', function(vehNetId, flood, alley, track)
    if lastVehicle and vehNetId == VehToNet(lastVehicle) then return end
    if not flood and not alley and not track then
        remoteStates[vehNetId] = nil
    else
        remoteStates[vehNetId] = { flood = flood, alley = alley, track = track }
    end
end)

-- Draw remote players’ lights (unchanged)
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        for netId, state in pairs(remoteStates) do
            if NetworkDoesNetworkIdExist(netId) then
                local veh = NetToVeh(netId)
                if DoesEntityExist(veh) then
                    -- Flood
                    if state.flood then
                        for _, pos in ipairs({
                            vector3(0,1.5,1.5),
                            vector3(-0.8,1.5,1.5),
                            vector3(0.8,1.5,1.5),
                        }) do
                            local wp  = GetOffsetFromEntityInWorldCoords(veh, pos.x,pos.y,pos.z)
                            local fwd = GetEntityForwardVector(veh)
                            DrawSpotLight(
                              wp.x, wp.y, wp.z,
                              fwd.x, fwd.y, 0.0,
                              255,255,255,40.0,40.0,10.0,50.0,40.0
                            )
                        end
                    end

                    -- Alley
                    if state.alley then
                        local posR = GetOffsetFromEntityInWorldCoords(veh, 0.8,0.0,1.5)
                        local posL = GetOffsetFromEntityInWorldCoords(veh,-0.8,0.0,1.5)
                        local fwd  = GetEntityForwardVector(veh)
                        local fwdXY= vector3(fwd.x,fwd.y,0)
                        local mag  = math.sqrt(fwdXY.x^2 + fwdXY.y^2) or 1.0
                        fwdXY = fwdXY / mag
                        local right = vector3(fwdXY.y,-fwdXY.x,-0.1)
                        local left  = vector3(-fwdXY.y,fwdXY.x,-0.1)
                        DrawSpotLight(
                          posR.x,posR.y,posR.z,
                          right.x,right.y,right.z,
                          255,255,255,30.0,20.0,1.0,35.0,5.0
                        )
                        DrawSpotLight(
                          posL.x,posL.y,posL.z,
                          left.x,left.y,left.z,
                          255,255,255,30.0,20.0,1.0,35.0,5.0
                        )
                    end

                    -- Track
                    if state.track then
                        local pos = GetOffsetFromEntityInWorldCoords(veh,0.8,0.7,1.5)
                        local dir = GetEntityForwardVector(veh)
                        dir = vector3(dir.x,dir.y,0)
                        local mag = math.sqrt(dir.x^2 + dir.y^2) or 1.0
                        dir = dir / mag
                        DrawSpotLight(
                          pos.x,pos.y,pos.z,
                          dir.x,dir.y,0.0,
                          221,221,221,50.0,30.0,4.3,25.0,28.6
                        )
                    end
                else
                    remoteStates[netId] = nil
                end
            else
                remoteStates[netId] = nil
            end
        end
    end
end)

-- Request full sync on spawn
AddEventHandler('playerSpawned', function()
    TriggerServerEvent('spotlights:requestSync')
end)
