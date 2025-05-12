Bridge.Callback.Register("mrc-holyman:weaponDamageEvent", function(data)
    print("mrc-holyman:weaponDamageEvent")
    local ped = PlayerPedId()
    local players = GetActivePlayers()
    local lPlayerCoords = GetEntityCoords(ped)
    for _, playerId in pairs(players) do
        local playerPed = GetPlayerPed(playerId)
        print("Player ID: " .. GetPlayerServerId(playerId) .. " Ped ID: " .. playerPed)
        local playerWeapon = GetSelectedPedWeapon(playerPed)
        if playerWeapon == Config.WeaponName then 
            local playerCoords = GetEntityCoords(playerPed)
            local distance = #(playerCoords - lPlayerCoords)
            if distance < (Config.ReviveRitual and Config.ReviveRitual.WeaponDamageCheckDistance or 2.0) then
                local currentHealth = GetEntityHealth(ped) + (Config.Healing and Config.Healing.Amount or 10) 
                local maxHealth = GetEntityMaxHealth(ped)
                local minVal = math.min(currentHealth, maxHealth)
                SetEntityHealth(ped, minVal)
            end
        end
    end
    return true
end)

local tracked = {}
Bridge.ClientEntity.RegisterAction('Track', function(entityData, _type)
    if not _type or _type ~= 'pedestal' then return end
    if not entityData then return end
    tracked[entityData.id] = entityData
end)


Bridge.ClientEntity.RegisterAction('Target', function(entityData, _type, target)
    if not _type then return end
    if not entityData then return end
    local entity = entityData.spawned
    if not entity then return end
    print('type', _type)
    if _type ~= 'pedestal' then return end
    local targetPed = GetPlayerPed(target)
    local reviveRitualCfg = Config.ReviveRitual or {}
    Bridge.Target.AddLocalEntity(entity, {
        {
            name = reviveRitualCfg.Label and string.format(reviveRitualCfg.Label, GetPlayerName(target)) or 'Revive', 
            icon = reviveRitualCfg.Icon or 'fa-solid fa-cross',
            label = reviveRitualCfg.Label and string.format(reviveRitualCfg.Label, GetPlayerName(target)) or 'Revive',
            onSelect = function()
                local id = entityData.id
                TriggerServerEvent('mrc-holyman:server:ParticipateInRitual', id, target)
            end
        }
    })
end)

RegisterNetEvent("mrc-holyman:client:StartRitual", function(pedestal)
    local target = pedestal.target    
    local targetPed = GetPlayerPed(GetPlayerFromServerId(target))
    local priestSrc = pedestal.src
    local id = pedestal.id
    local cultists = pedestal.cultists
    local lPed = PlayerPedId()

    local reviveRitualCfg = Config.ReviveRitual or {}

    for k, v in pairs(cultists) do
        local src = tonumber(k)
        local tempPed = GetPlayerPed(GetPlayerFromServerId(src))
        if tempPed == lPed then
            ForceLightningFlash()
            local isPriest = src == priestSrc
            
            local participantCfg = {}
            if isPriest then
                participantCfg = reviveRitualCfg.Priest or {}
            else
                participantCfg = reviveRitualCfg.Followers or {}
            end

            local pbSettings = participantCfg.ProgressBar or {}
            local pbAnimSettings = pbSettings.animation or {}
            local pbPropSettings = pbSettings.prop or {}
            local pbDisableSettings = pbSettings.disable or {move = true, combat = true}


            Bridge.ProgressBar.Open({
                duration = pbSettings.duration or 5000,
                label = pbSettings.label or "Praying",
                controlDisables = pbDisableSettings,
                animation = {
                    animDict = pbAnimSettings.animDict or pbAnimSettings.dict or "anim@amb@business@weed@weed_inspecting_lo_med_hi@",
                    anim = pbAnimSettings.anim or pbAnimSettings.name or "weed_spraybottle_crouch_spraying_01_inspectorfemale",
                    flag = pbAnimSettings.flag or 1
                },
                prop = {
                    model = pbPropSettings.model or "v_res_fa_candle04",
                    coords = pbPropSettings.coords or vector3(0.05, 0.05, 0.0),
                    rotation = pbPropSettings.rotation or vector3(0.0, 140.0, 90.0)
                },
            }, function(success)
                if not isPriest then return end  
                local priestActionsCfg = reviveRitualCfg.Priest or {}
                Wait(priestActionsCfg.PostProgressBarWait or 2000)
                local priestMainAnimCfg = priestActionsCfg.Animation or {}
                Bridge.Anim.Play(id .. "_priest", lPed, priestMainAnimCfg.dict or "misscommon@response", priestMainAnimCfg.name or "bring_it_on", nil, nil, priestMainAnimCfg.duration or 5000)             
            end, true)
        end 
    end

    if lPed ~= targetPed then return end

    local targetActionsCfg = reviveRitualCfg.Followers or {} 
    local targetMainAnimCfg = targetActionsCfg.Animation or {}
    
    local effectDuration = targetActionsCfg.EffectDuration or 5000
    local waitTime = math.random(targetActionsCfg.WaitTimeMin or 1000, targetActionsCfg.WaitTimeMax or 2000) 
    Wait(waitTime)
    local syncTime = effectDuration - waitTime
    Bridge.Anim.Play(id .. "_target", lPed, targetMainAnimCfg.dict or "weapon@w_pi_stungun", targetMainAnimCfg.name or "damage", nil, nil, syncTime > 0 and syncTime or 1)
    local cutsceneData = Bridge.Cutscene.Create('MP_INT_MCS_18_A1', GetEntityCoords(lPed))
    Bridge.Cutscene.Start(cutsceneData)
    TriggerServerEvent('mrc-holyman:server:RitualDone', id)
    ForceLightningFlash()   
end)

RegisterNetEvent('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    for k, v in pairs(tracked) do
        local entity = v.spawned
        if DoesEntityExist(entity) then
            Bridge.Point.Remove(v.id)
            DeleteEntity(entity)
        end
    end
end)