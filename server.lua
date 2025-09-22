local function registerToggleEvent(eventBaseName)
    RegisterServerEvent(eventBaseName .. "_s")
    AddEventHandler(eventBaseName .. "_s", function(param) TriggerClientEvent(eventBaseName .. "_c", -1, source, param) end)
end

registerToggleEvent("lvc_TogDfltSrnMuted")
registerToggleEvent("lvc_SetLxSirenState")
registerToggleEvent("lvc_TogPwrcallState")
registerToggleEvent("lvc_SetAirManuState")
registerToggleEvent("lvc_TogIndicState")