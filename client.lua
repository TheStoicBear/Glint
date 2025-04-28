local lastVehicle = nil  -- <== new: store the last vehicle we were in
local floodlightsOn      = false
local alleyLightsOn      = false
local trackMode          = false
local trackedVehicle     = nil
local lastLTime          = 0
local doubleTapThreshold = 300    -- ms for single/double tap
local uiVisible          = false
local uiFocused          = false
local remoteStates = {}  -- [ vehNetId ] = { flood=bool, alley=bool, track=bool }
local rotationSmoothFactor = 0.15
local currentTrackDir     = vector3(1.0, 0.0, 0.0)
local trackMaxDistance    = 250.0
local trackAngleThreshold = math.cos(math.rad(90))

local isOutOfVehicle = true -- Tracks if the player is out of vehicle

-- Acquire first valid target ahead
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
        SetNuiFocus(true, true)  -- Focus on the UI
        SendNUIMessage({
            action = 'open',
            flood  = floodlightsOn,
            alley  = alleyLightsOn,
            track  = trackMode,
        })
        SendNUIMessage({ action = 'focus', focus = true })
    else
        uiFocused = false
        SetNuiFocus(false, false)  -- Remove focus from UI
        SendNUIMessage({ action = 'close' })
        SendNUIMessage({ action = 'focus', focus = false })
    end
end, false)

-- UI callbacks
RegisterNUICallback('toggleFlood', function(data, cb)
    floodlightsOn = not floodlightsOn
    -- reset others
    alleyLightsOn, trackMode, trackedVehicle = false, false, nil
    SendNUIMessage({
        action = 'update',
        flood  = floodlightsOn,
        alley  = alleyLightsOn,
        track  = trackMode,
    })
    cb('ok')
end)

RegisterNUICallback('toggleAlley', function(data, cb)
    alleyLightsOn = not alleyLightsOn
    -- reset others
    floodlightsOn, trackMode, trackedVehicle = false, false, nil
    SendNUIMessage({
        action = 'update',
        flood  = floodlightsOn,
        alley  = alleyLightsOn,
        track  = trackMode,
    })
    cb('ok')
end)

RegisterNUICallback('toggleTrack', function(data, cb)
    trackMode = not trackMode
    -- reset others
    floodlightsOn, alleyLightsOn = trackMode, false
    trackedVehicle = nil
    SendNUIMessage({
        action = 'update',
        flood  = floodlightsOn,
        alley  = alleyLightsOn,
        track  = trackMode,
    })
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

-- toggleAll: if any light is on, turn all off; else turn all on
local function toggleAll()
    local anyOn = floodlightsOn or alleyLightsOn or trackMode
    floodlightsOn  = not anyOn
    alleyLightsOn  = not anyOn
    trackMode      = not anyOn
    trackedVehicle = nil

    SendNUIMessage({
        action = 'update',
        flood = floodlightsOn,
        alley = alleyLightsOn,
        track = trackMode,
    })
end

RegisterNUICallback('toggleAll', function(data, cb)
    toggleAll()
    cb('ok')
end)

-- L key single/double tap for flood/ally
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if IsControlJustReleased(0, 182) then -- L key
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

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        local ped = PlayerPedId()

        if IsPedInAnyVehicle(ped, false) then
            isOutOfVehicle = false
            lastVehicle = GetVehiclePedIsIn(ped, false)
        else
            isOutOfVehicle = true
        end

        -- Use lastVehicle if we are out of vehicle
        local veh = nil
        if not isOutOfVehicle then
            veh = GetVehiclePedIsIn(ped, false)
        else
            veh = lastVehicle
        end

        if veh and DoesEntityExist(veh) then
            if not isOutOfVehicle or (isOutOfVehicle and floodlightsOn or alleyLightsOn or trackMode) then
                -- Floodlights: 3 beams from front-center, front-left, front-right
                if floodlightsOn then
                    local sideOffset, frontOffset, height = 0.8, 1.5, 1.5
                    local positions = {
                        vector3(0.0, frontOffset, height),  -- center
                        vector3(-sideOffset, frontOffset, height),  -- left
                        vector3(sideOffset, frontOffset, height),  -- right
                    }
                    local fwd = GetEntityForwardVector(veh)
                    for _, pos in ipairs(positions) do
                        local worldPos = GetOffsetFromEntityInWorldCoords(veh, pos.x, pos.y, pos.z)
                        DrawSpotLight(
                            worldPos.x, worldPos.y, worldPos.z,
                            fwd.x, fwd.y, 0.0,
                            255, 255, 255,
                            40.0,   -- inner cone radius
                            40.0,   -- outer cone radius
                            10.0,   -- falloff
                            50.0,   -- distance
                            40.0    -- intensity
                        )
                    end
                end

                -- Alley lights (roof sides)
                if alleyLightsOn then
                    local sideOffset, heightOffset = 0.8, 1.5
                    local frontOffset = 0.0
                    local posR = GetOffsetFromEntityInWorldCoords(veh, sideOffset, frontOffset, heightOffset)
                    local posL = GetOffsetFromEntityInWorldCoords(veh, -sideOffset, frontOffset, heightOffset)
                    local fwd = GetEntityForwardVector(veh)
                    local fwdXY = vector3(fwd.x, fwd.y, 0.0)
                    local mag = math.sqrt(fwdXY.x^2 + fwdXY.y^2) or 1.0
                    fwdXY = vector3(fwdXY.x/mag, fwdXY.y/mag, 0.0)
                    local right = vector3(fwdXY.y, -fwdXY.x, -0.1)  -- Slight downward tilt
                    local left  = vector3(-fwdXY.y, fwdXY.x, -0.1)  -- Slight downward tilt
                    DrawSpotLight(posR.x, posR.y, posR.z,
                                  right.x, right.y, right.z,
                                  255, 255, 255, 30.0, 20.0, 1.0, 35.0, 5.0)
                    DrawSpotLight(posL.x, posL.y, posL.z,
                                  left.x, left.y, left.z,
                                  255, 255, 255, 30.0, 20.0, 1.0, 35.0, 5.0)
                end

                -- Track light (roof rear-center)
                if trackMode then
                    if not trackedVehicle then
                        trackedVehicle = AcquireTarget()
                    end
                    local pos = GetOffsetFromEntityInWorldCoords(veh, 0.8, 0.7, 1.5)
                    local desired
                    if trackedVehicle and DoesEntityExist(trackedVehicle) then
                        desired = GetEntityCoords(trackedVehicle) - pos
                    else
                        desired = GetEntityForwardVector(veh)
                    end
                    desired = vector3(desired.x, desired.y, 0.0)
                    local mag = math.sqrt(desired.x^2 + desired.y^2) or 1.0
                    desired = vector3(desired.x/mag, desired.y/mag, 0.0)
                    currentTrackDir = currentTrackDir + (desired - currentTrackDir) * rotationSmoothFactor
                    DrawSpotLight(pos.x, pos.y, pos.z,
                                  currentTrackDir.x, currentTrackDir.y, 0.0,
                                  221, 221, 221, 50.0, 30.0, 4.3, 25.0, 28.6)
                end
            end
        end
    end
end)

local function sendMyState()
    if lastVehicle and DoesEntityExist(lastVehicle) then
        TriggerServerEvent('spotlights:updateState',
            VehToNet(lastVehicle),
            floodlightsOn,
            alleyLightsOn,
            trackMode
        )
    end
end

-- after any toggle, push new state
AddEventHandler('onResourceStart', function()
    local orig = SendNUIMessage
    SendNUIMessage = function(msg)
        orig(msg)
        if msg.action == 'update' then
            Citizen.Wait(1)
            sendMyState()
        end
    end
end)
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if IsControlJustReleased(0, 182) then
            Citizen.Wait(1)
            sendMyState()
        end
    end
end)

-- receive a single-vehicle state update
RegisterNetEvent('spotlights:syncStates')
AddEventHandler('spotlights:syncStates', function(vehNetId, flood, alley, track)
    -- if every mode is off, drop the entry; otherwise store it
    if not flood and not alley and not track then
        remoteStates[vehNetId] = nil
    else
        remoteStates[vehNetId] = { flood = flood, alley = alley, track = track }
    end
end)

-- request full sync on spawn
AddEventHandler('playerSpawned', function()
    TriggerServerEvent('spotlights:requestSync')
end)


-- draw remote players’ lights (fixed)
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        for netId, state in pairs(remoteStates) do
            -- only proceed if the network ID still exists
            if NetworkDoesNetworkIdExist(netId) then
                local veh = NetToVeh(netId)
                if DoesEntityExist(veh) then
                    if state.flood then
                        local sideOffset, frontOffset, height = 0.8, 1.5, 1.5
                        local positions = {
                            vector3(0.0, frontOffset, height),
                            vector3(-sideOffset, frontOffset, height),
                            vector3(sideOffset, frontOffset, height),
                        }
                        local fwd = GetEntityForwardVector(veh)
                        for _, pos in ipairs(positions) do
                            local worldPos = GetOffsetFromEntityInWorldCoords(veh, pos.x, pos.y, pos.z)
                            DrawSpotLight(
                                worldPos.x, worldPos.y, worldPos.z,
                                fwd.x, fwd.y, 0.0,
                                255, 255, 255,
                                40.0, 40.0, 10.0, 50.0, 40.0
                            )
                        end
                    end
                    if state.alley then
                        local sideOffset, heightOffset = 0.8, 1.5
                        local frontOffset = 0.0
                        local posR = GetOffsetFromEntityInWorldCoords(veh, sideOffset, frontOffset, heightOffset)
                        local posL = GetOffsetFromEntityInWorldCoords(veh, -sideOffset, frontOffset, heightOffset)
                        local fwd = GetEntityForwardVector(veh)
                        local fwdXY = vector3(fwd.x, fwd.y, 0.0)
                        local mag = math.sqrt(fwdXY.x^2 + fwdXY.y^2) or 1.0
                        fwdXY = vector3(fwdXY.x/mag, fwdXY.y/mag, 0.0)
                        local right = vector3(fwdXY.y, -fwdXY.x, -0.1)
                        local left  = vector3(-fwdXY.y, fwdXY.x, -0.1)
                        DrawSpotLight(posR.x, posR.y, posR.z, right.x, right.y, right.z, 255,255,255,30.0,20.0,1.0,35.0,5.0)
                        DrawSpotLight(posL.x, posL.y, posL.z, left.x, left.y, left.z, 255,255,255,30.0,20.0,1.0,35.0,5.0)
                    end
                    if state.track then
                        local pos = GetOffsetFromEntityInWorldCoords(veh, 0.8, 0.7, 1.5)
                        local dir = GetEntityForwardVector(veh)
                        dir = vector3(dir.x, dir.y, 0.0)
                        local mag = math.sqrt(dir.x^2 + dir.y^2) or 1.0
                        dir = vector3(dir.x/mag, dir.y/mag, 0.0)
                        DrawSpotLight(pos.x, pos.y, pos.z, dir.x, dir.y, 0.0, 221,221,221,50.0,30.0,4.3,25.0,28.6)
                    end
                else
                    -- vehicle no longer exists: remove from table
                    remoteStates[netId] = nil
                end
            else
                -- network ID invalid: remove from table
                remoteStates[netId] = nil
            end
        end
    end
end)