local count_bcast_timer, delay_bcast_timer = 0, 200
local count_sndclean_timer, delay_sndclean_timer = 0, 400
local count_ind_timer, delay_ind_timer = 0, 180

local actv_ind_timer = false
local actv_lxsrnmute_temp = false
local srntone_temp = 0
local dsrn_mute = true
local lastVeh = nil

local state_indic = {}
local state_lxsiren = {}
local state_pwrcall = {}
local state_airmanu = {}

local ind_state_o, ind_state_l, ind_state_r, ind_state_h = 0, 1, 2, 3

local snd_lxsiren = {}
local snd_pwrcall = {}
local snd_airmanu = {}

local eModelsWithFireSrn = { 'gbfirevoyager' }
local eModelsWithPcall = { 'sandbulance' }

local useLR = true -- default: true = on
local lrTime = 7 -- seconds
RegisterCommand('lr', function() useLR = not useLR end)

local function PlayClick() TriggerEvent('lux_vehcontrol:ELSClick', 'Beep', 0.7) end

CreateThread(function()
    while true do
        Wait(lrTime*1000)
        local player_s = GetPlayerFromServerId(sender)
        local ped_s = GetPlayerPed(player_s)
        local veh = GetVehiclePedIsUsing(ped_s)
        if GetPedInVehicleSeat(veh, -1) == ped_s and IsVehicleSirenOn(veh) and GetVehicleClass(veh) == 18 and useLR then PlayClick() end
    end
end)

local function IsModelInList(veh, modelList)
    local model = GetEntityModel(veh)
    for _, mdlName in ipairs(modelList) do
        if model == GetHashKey(mdlName) then return true end
    end
    return false
end

local function UseFiretruckSiren(veh) return IsModelInList(veh, eModelsWithFireSrn) end
local function UsePowerCallAuxSiren(veh) return IsModelInList(veh, eModelsWithPcall) end

local function CleanupSounds()
    count_sndclean_timer = count_sndclean_timer + 1
    if count_sndclean_timer <= delay_sndclean_timer then return end
    count_sndclean_timer = 0
    local function cleanupSoundTable(stateTable, soundTable)
		for veh, state in pairs(stateTable) do
			if ((type(state) == "number" and state > 0) or state == true) and (not DoesEntityExist(veh) or IsEntityDead(veh) or (stateTable == state_airmanu and IsVehicleSeatFree(veh, -1))) then
				if soundTable[veh] then
					StopSound(soundTable[veh])
					ReleaseSoundId(soundTable[veh])
					soundTable[veh] = nil
					stateTable[veh] = nil
				end
			end
		end
	end
    cleanupSoundTable(state_lxsiren, snd_lxsiren)
    cleanupSoundTable(state_pwrcall, snd_pwrcall)
    cleanupSoundTable(state_airmanu, snd_airmanu)
end

function ToggleIndicator(veh, newstate)
    if DoesEntityExist(veh) and not IsEntityDead(veh) then
        local leftOn, rightOn = false, false
        if newstate == ind_state_l then
            leftOn = true
        elseif newstate == ind_state_r then
            rightOn = true
        elseif newstate == ind_state_h then
            leftOn, rightOn = true, true
        end
        SetVehicleIndicatorLights(veh, 0, rightOn)
        SetVehicleIndicatorLights(veh, 1, leftOn)
        state_indic[veh] = newstate
    end
end

function ToggleMuteDefaultSiren(veh, toggle)
    if DoesEntityExist(veh) and not IsEntityDead(veh) then DisableVehicleImpactExplosionActivation(veh, toggle) end
end

local function StopAndReleaseSound(veh, soundTable)
    if soundTable[veh] then
        StopSound(soundTable[veh])
        ReleaseSoundId(soundTable[veh])
        soundTable[veh] = nil
    end
end

function SetLXSirentStateForVehicle(veh, newstate)
    if DoesEntityExist(veh) and not IsEntityDead(veh) then
        if newstate ~= state_lxsiren[veh] then
            StopAndReleaseSound(veh, snd_lxsiren)
            if newstate == 1 then
                if UseFiretruckSiren(veh) then
                    ToggleMuteDefaultSiren(veh, false)
                else
                    local sndId = GetSoundId()
                    snd_lxsiren[veh] = sndId
                    PlaySoundFromEntity(sndId, 'VEHICLES_HORNS_SIREN_1', veh, 0, 0, 0)
                    ToggleMuteDefaultSiren(veh, true)
                end
            elseif newstate == 2 then
                local sndId = GetSoundId()
                snd_lxsiren[veh] = sndId
                PlaySoundFromEntity(sndId, 'VEHICLES_HORNS_SIREN_2', veh, 0, 0, 0)
                ToggleMuteDefaultSiren(veh, true)
            elseif newstate == 3 then
                local sndId = GetSoundId()
                snd_lxsiren[veh] = sndId
                if UseFiretruckSiren(veh) then
                    PlaySoundFromEntity(sndId, 'VEHICLES_HORNS_AMBULANCE_WARNING', veh, 0, 0, 0)
                else
                    PlaySoundFromEntity(sndId, 'VEHICLES_HORNS_POLICE_WARNING', veh, 0, 0, 0)
                end
                ToggleMuteDefaultSiren(veh, true)
            else
                ToggleMuteDefaultSiren(veh, true)
            end
            state_lxsiren[veh] = newstate
        end
    end
end

function TogglePowerCallStateForVehicle(veh, toggle)
    if DoesEntityExist(veh) and not IsEntityDead(veh) then
        if toggle then
            if not snd_pwrcall[veh] then
                local sndId = GetSoundId()
                snd_pwrcall[veh] = sndId
                if UsePowerCallAuxSiren(veh) then
                    PlaySoundFromEntity(sndId, 'VEHICLES_HORNS_AMBULANCE_WARNING', veh, 0, 0, 0)
                else
                    PlaySoundFromEntity(sndId, 'VEHICLES_HORNS_SIREN_1', veh, 0, 0, 0)
                end
            end
        else
            StopAndReleaseSound(veh, snd_pwrcall)
        end
        state_pwrcall[veh] = toggle
    end
end

function SetAirManualStateForVehicle(veh, newstate)
    if DoesEntityExist(veh) and not IsEntityDead(veh) then
        if newstate ~= state_airmanu[veh] then
            StopAndReleaseSound(veh, snd_airmanu)
            if newstate == 1 then
                local sndId = GetSoundId()
                snd_airmanu[veh] = sndId
                if UseFiretruckSiren(veh) then
                    PlaySoundFromEntity(sndId, 'VEHICLES_HORNS_FIRETRUCK_WARNING', veh, 0, 0, 0)
                else
                    PlaySoundFromEntity(sndId, 'SIRENS_AIRHORN', veh, 0, 0, 0)
                end
            elseif newstate == 2 then
                local sndId = GetSoundId()
                snd_airmanu[veh] = sndId
                PlaySoundFromEntity(sndId, 'VEHICLES_HORNS_SIREN_1', veh, 0, 0, 0)
            elseif newstate == 3 then
                local sndId = GetSoundId()
                snd_airmanu[veh] = sndId
                PlaySoundFromEntity(sndId, 'VEHICLES_HORNS_SIREN_2', veh, 0, 0, 0)
            end
            state_airmanu[veh] = newstate
        end
    end
end

local function GetSenderVehicle(sender)
    local player_s = GetPlayerFromServerId(sender)
    if not player_s then return nil end
    local ped_s = GetPlayerPed(player_s)
    if not DoesEntityExist(ped_s) or IsEntityDead(ped_s) or ped_s == GetPlayerPed(-1) then return nil end
    if IsPedInAnyVehicle(ped_s, false) then return GetVehiclePedIsUsing(ped_s) end
    return nil
end

function SetAirManualStateForVehicleClick(veh, newstate)
    if DoesEntityExist(veh) and not IsEntityDead(veh) then
        if newstate ~= state_airmanu[veh] then
            if snd_airmanu[veh] ~= nil then
                StopSound(snd_airmanu[veh])
                ReleaseSoundId(snd_airmanu[veh])
                snd_airmanu[veh] = nil
            end
            if newstate >= 1 and newstate <= 3 then
                snd_airmanu[veh] = GetSoundId()
                PlayClick()
                if newstate == 1 then
                    if UseFiretruckSiren(veh) then
                        PlaySoundFromEntity(snd_airmanu[veh], 'VEHICLES_HORNS_FIRETRUCK_WARNING', veh, 0, 0, 0)
                    else
                        PlaySoundFromEntity(snd_airmanu[veh], 'SIRENS_AIRHORN', veh, 0, 0, 0)
                    end
                elseif newstate == 2 then
                    PlaySoundFromEntity(snd_airmanu[veh], 'VEHICLES_HORNS_SIREN_1', veh, 0, 0, 0)
                else
                    PlaySoundFromEntity(snd_airmanu[veh], 'VEHICLES_HORNS_SIREN_2', veh, 0, 0, 0)
                end
            end
            state_airmanu[veh] = newstate
        end
    end
end

local function HandleVehicleStateEvent(sender, callback, ...)
    local veh = GetSenderVehicle(sender)
    if veh then callback(veh, ...) end
end

RegisterNetEvent('lvc_TogIndicState_c')
AddEventHandler('lvc_TogIndicState_c', function(sender, newstate)
    HandleVehicleStateEvent(sender, ToggleIndicator, newstate)
end)

AddEventHandler('lux_vehcontrol:ELSClick', function(soundFile, soundVolume)
    SendNUIMessage({transactionType = 'playSound', transactionFile = soundFile, transactionVolume = soundVolume})
end)

RegisterNetEvent('lvc_TogDfltSrnMuted_c')
AddEventHandler('lvc_TogDfltSrnMuted_c', function(sender, toggle)
    HandleVehicleStateEvent(sender, ToggleMuteDefaultSiren, toggle)
end)

RegisterNetEvent('lvc_SetLxSirenState_c')
AddEventHandler('lvc_SetLxSirenState_c', function(sender, newstate)
    HandleVehicleStateEvent(sender, SetLXSirentStateForVehicle, newstate)
end)

RegisterNetEvent('lvc_TogPwrcallState_c')
AddEventHandler('lvc_TogPwrcallState_c', function(sender, toggle)
    HandleVehicleStateEvent(sender, TogglePowerCallStateForVehicle, toggle)
end)

RegisterNetEvent('lvc_SetAirManuState_c')
AddEventHandler('lvc_SetAirManuState_c', function(sender, newstate)
    HandleVehicleStateEvent(sender, SetAirManualStateForVehicle, newstate)
end)

RegisterNetEvent('Setlvc_SetAirManuState_clientclick')
AddEventHandler('Setlvc_SetAirManuState_clientclick', function(sender, newstate)
    HandleVehicleStateEvent(sender, SetAirManualStateForVehicleClick, newstate)
end)

CreateThread(function()
    while true do
        local playerPed = PlayerPedId()
        local veh = GetVehiclePedIsUsing(playerPed)
        local isDriver = (veh ~= 0 and GetPedInVehicleSeat(veh, -1) == playerPed)
        if lastVeh and lastVeh ~= veh then
            SetLXSirentStateForVehicle(lastVeh, 0)
            TogglePowerCallStateForVehicle(lastVeh, false)
            SetAirManualStateForVehicle(lastVeh, 0)
            state_indic[lastVeh] = ind_state_o
            ToggleIndicator(lastVeh, ind_state_o)
            count_bcast_timer = 0
            count_sndclean_timer = 0
            count_ind_timer = 0
            lastVeh = nil
        end
        if veh ~= 0 and isDriver then
            lastVeh = veh
        else
            if lastVeh then
                SetLXSirentStateForVehicle(lastVeh, 0)
                TogglePowerCallStateForVehicle(lastVeh, false)
                SetAirManualStateForVehicle(lastVeh, 0)
                state_indic[lastVeh] = ind_state_o
                ToggleIndicator(lastVeh, ind_state_o)
                count_bcast_timer = 0
                count_sndclean_timer = 0
                count_ind_timer = 0
                lastVeh = nil
            end
            Wait(500)
            goto continue
        end
        Wait(0)
        ::continue::
    end
end)

CreateThread(function()
    while true do
        CleanupSounds()
        local playerPed = PlayerPedId()
        if not IsPedInAnyVehicle(playerPed, false) then Wait(0) end
        local veh = GetVehiclePedIsUsing(playerPed)
        if GetPedInVehicleSeat(veh, -1) ~= playerPed then Wait(0) end
        DisableControlAction(0, 84, true)
        DisableControlAction(0, 83, true)
        local currentState = state_indic[veh]
        if currentState ~= ind_state_o and currentState ~= ind_state_l and currentState ~= ind_state_r and currentState ~= ind_state_h then
            state_indic[veh] = ind_state_o
            currentState = ind_state_o
        end
        if actv_ind_timer and (currentState == ind_state_l or currentState == ind_state_r) then
            if GetEntitySpeed(veh) < 6 then
                count_ind_timer = 0
            else
                if count_ind_timer > delay_ind_timer then
                    count_ind_timer = 0
                    actv_ind_timer = false
                    state_indic[veh] = ind_state_o
                    ToggleIndicator(veh, ind_state_o)
                    count_bcast_timer = delay_bcast_timer
                else
                    count_ind_timer = count_ind_timer + 1
                end
            end
        end
        local vehClass = GetVehicleClass(veh)
        if vehClass == 18 then
            local controlsToDisable = {86, 172, 81, 82, 19, 85, 80}
            for _, ctrl in ipairs(controlsToDisable) do DisableControlAction(0, ctrl, true) end
            SetVehRadioStation(veh, 'OFF')
            SetVehicleRadioEnabled(veh, false)
            state_lxsiren[veh] = (state_lxsiren[veh] == 1 or state_lxsiren[veh] == 2 or state_lxsiren[veh] == 3) and state_lxsiren[veh] or 0
            state_pwrcall[veh] = state_pwrcall[veh] == true
            state_airmanu[veh] = (state_airmanu[veh] == 1 or state_airmanu[veh] == 2 or state_airmanu[veh] == 3) and state_airmanu[veh] or 0
            if UseFiretruckSiren(veh) and state_lxsiren[veh] == 1 then
                ToggleMuteDefaultSiren(veh, false)
                dsrn_mute = false
            else
                ToggleMuteDefaultSiren(veh, true)
                dsrn_mute = true
            end
            if not IsVehicleSirenOn(veh) then
                if state_lxsiren[veh] > 0 then
                    SetLXSirentStateForVehicle(veh, 0)
                    count_bcast_timer = delay_bcast_timer
                end
                if state_pwrcall[veh] then
                    TogglePowerCallStateForVehicle(veh, false)
                    count_bcast_timer = delay_bcast_timer
                end
            end
            if not IsPauseMenuActive() then
                if IsDisabledControlJustReleased(0, 85) then
                    if IsVehicleSirenOn(veh) then
                        TriggerEvent('lux_vehcontrol:ELSClick', 'On', 0.7)
                        SetVehicleSiren(veh, false)
                    else
                        TriggerEvent('lux_vehcontrol:ELSClick', 'On', 0.5)
                        Wait(150)
                        SetVehicleSiren(veh, true)
                        count_bcast_timer = delay_bcast_timer
                    end
                elseif IsDisabledControlJustReleased(0, 19) or IsDisabledControlJustReleased(0, 82) then
                    local cstate = state_lxsiren[veh]
                    if cstate == 0 and IsVehicleSirenOn(veh) then
                        PlayClick()
                        SetLXSirentStateForVehicle(veh, 1)
                        count_bcast_timer = delay_bcast_timer
                    elseif cstate ~= 0 then
                        PlayClick()
                        SetLXSirentStateForVehicle(veh, 0)
                        count_bcast_timer = delay_bcast_timer
                    end
                elseif IsDisabledControlJustReleased(0, 172) then
                    if state_pwrcall[veh] then
                        PlayClick()
                        TogglePowerCallStateForVehicle(veh, false)
                        count_bcast_timer = delay_bcast_timer
                    elseif IsVehicleSirenOn(veh) then
                        PlayClick()
                        TogglePowerCallStateForVehicle(veh, true)
                        count_bcast_timer = delay_bcast_timer
                    end
                end
                if state_lxsiren[veh] > 0 then
                    if IsDisabledControlJustReleased(0, 175) or IsDisabledControlJustReleased(0, 80) then
                        if IsVehicleSirenOn(veh) then
                            local cstate = state_lxsiren[veh]
                            local nstate = (cstate == 1) and 2 or (cstate == 2) and 3 or 1
                            PlayClick()
                            SetLXSirentStateForVehicle(veh, nstate)
                            count_bcast_timer = delay_bcast_timer
                        end
                    elseif IsDisabledControlJustReleased(0, 174) then
                        if IsVehicleSirenOn(veh) then
                            local cstate = state_lxsiren[veh]
                            local nstate = (cstate == 1) and 3 or (cstate == 3) and 2 or 1
                            PlayClick()
                            SetLXSirentStateForVehicle(veh, nstate)
                            count_bcast_timer = delay_bcast_timer
                        end
                    end
                end
                local actv_manu = (state_lxsiren[veh] < 1) and (IsDisabledControlPressed(0, 80) or IsDisabledControlPressed(0, 81)) or false
                local actv_horn = IsDisabledControlPressed(0, 86)
                local hmanu_state_new = 0
                if actv_horn and not actv_manu then
                    hmanu_state_new = 1
                elseif not actv_horn and actv_manu then
                    hmanu_state_new = 2
                elseif actv_horn and actv_manu then
                    hmanu_state_new = 3
                end
                if hmanu_state_new == 1 and not UseFiretruckSiren(veh) then
                    if state_lxsiren[veh] > 0 and not actv_lxsrnmute_temp then
                        srntone_temp = state_lxsiren[veh]
                        SetLXSirentStateForVehicle(veh, 0)
                        actv_lxsrnmute_temp = true
                    end
                elseif not UseFiretruckSiren(veh) then
                    if actv_lxsrnmute_temp then
                        SetLXSirentStateForVehicle(veh, srntone_temp)
                        actv_lxsrnmute_temp = false
                    end
                end
                if state_airmanu[veh] ~= hmanu_state_new then
                    SetAirManualStateForVehicleClick(veh, hmanu_state_new)
                    count_bcast_timer = delay_bcast_timer
                end
            end
        end
        if vehClass ~= 14 and vehClass ~= 15 and vehClass ~= 16 and vehClass ~= 21 then
            if not IsPauseMenuActive() then
                if IsDisabledControlJustReleased(0, 84) then
                    if state_indic[veh] == ind_state_l then
                        state_indic[veh] = ind_state_o
                        actv_ind_timer = false
                    else
                        state_indic[veh] = ind_state_l
                        actv_ind_timer = true
                    end
                    ToggleIndicator(veh, state_indic[veh])
                    count_ind_timer = 0
                    count_bcast_timer = delay_bcast_timer
                elseif IsDisabledControlJustReleased(0, 83) then
                    if state_indic[veh] == ind_state_r then
                        state_indic[veh] = ind_state_o
                        actv_ind_timer = false
                    else
                        state_indic[veh] = ind_state_r
                        actv_ind_timer = true
                    end
                    ToggleIndicator(veh, state_indic[veh])
                    count_ind_timer = 0
                    count_bcast_timer = delay_bcast_timer
                elseif IsControlJustReleased(0, 202) and GetLastInputMethod(0) then
                    if state_indic[veh] == ind_state_h then
                        state_indic[veh] = ind_state_o
                    else
                        state_indic[veh] = ind_state_h
                    end
                    ToggleIndicator(veh, state_indic[veh])
                    actv_ind_timer = false
                    count_ind_timer = 0
                    count_bcast_timer = delay_bcast_timer
                end
            end
            if count_bcast_timer > delay_bcast_timer then
                count_bcast_timer = 0
                if vehClass == 18 then
                    TriggerServerEvent('lvc_TogDfltSrnMuted_s', dsrn_mute)
                    TriggerServerEvent('lvc_SetLxSirenState_s', state_lxsiren[veh])
                    TriggerServerEvent('lvc_TogPwrcallState_s', state_pwrcall[veh])
                    TriggerServerEvent('lvc_SetAirManuState_s', state_airmanu[veh])
                    TriggerEvent('Setlvc_SetAirManuState_clientclick')
                end
                TriggerServerEvent('lvc_TogIndicState_s', state_indic[veh])
            else
                count_bcast_timer = count_bcast_timer + 1
            end
        end
        ::continue::
        Wait(0)
    end
end)