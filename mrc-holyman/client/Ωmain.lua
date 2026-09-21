
local Bobbing = {}
local Circling = {}
local Emitting = {}
local Markers = {}

local function PedistalConfig()
    return (Config.ReviveRitual and Config.ReviveRitual.Pedistal) or {}
end

local function StartMarkers(entityData)
    local id = entityData.id
    if Markers[id] then return end

    local configured = PedistalConfig().markers or {}
    if not next(configured) then return end

    local created = {}
    for k, v in pairs(configured) do
        if type(v) == 'table' then
            local markerId = string.format('%s-:Marker-%s', id, k)
            Bridge.Marker.Create({
                id = markerId,
                position = entityData.coords + (v.offset or vector3(0.0, 0.0, 0.0)),
                marker = v.marker or v.type or 1,
                rotation = v.rotation or vector3(0.0, 0.0, 0.0),
                size = v.size or vector3(0.5, 0.5, 0.5),
                color = v.color or vector3(255, 0, 0),
                alpha = v.alpha or 150,
                bobUpAndDown = v.bobUpAndDown,
                drawDistance = v.drawDistance or 50.0,
            })
            table.insert(created, markerId)
        end
    end
    Markers[id] = created
end

local function StopMarkers(entityData)
    local created = Markers[entityData.id]
    if not created then return end
    for _, markerId in pairs(created) do
        Bridge.Marker.Remove(markerId)
    end
    Markers[entityData.id] = nil
end

local function StartParticles(entityData)
    local id = entityData.id
    local entity = entityData.spawned
    if Emitting[id] then return end
    if not entity or not DoesEntityExist(entity) then return end

    local particles = PedistalConfig().particles or {}
    if not next(particles) then return end
    Emitting[id] = true

    CreateThread(function()
        for _, particle in pairs(particles) do
            if not Emitting[id] or entityData.spawned ~= entity or not DoesEntityExist(entity) then return end
            Bridge.Particle.CreateOnEntity(
                particle.dict,
                particle.ptfx,
                entity,
                particle.offset or vector3(0.0, 0.0, 0.0),
                particle.rotation or vector3(0.0, 0.0, 0.0),
                particle.size or 1.0,
                particle.color or vector3(255, 255, 255),
                particle.looped ~= false,
                particle.loopLength
            )
        end
    end)
end

local function StopParticles(entityData)
    local entity = entityData.spawned
    Emitting[entityData.id] = nil
    if entity and DoesEntityExist(entity) then
        RemoveParticleFxFromEntity(entity)
    end
end

local function StartBob(entityData, speed, height)
    local id = entityData.id
    if Bobbing[id] then return end
    local entity = entityData.spawned
    if not entity or not DoesEntityExist(entity) then return end
    Bobbing[id] = true

    CreateThread(function()
        local base = GetEntityCoords(entity)
        while Bobbing[id] and entityData.spawned == entity and DoesEntityExist(entity) do
            local z = base.z + math.sin(GetGameTimer() * (speed / 1000)) * height
            SetEntityCoords(entity, base.x, base.y, z, false, false, false, false)
            Wait(10)
        end
        Bobbing[id] = nil
    end)
end

local function StartCircle(entityData, radius, speed, index, count)
    local id = entityData.id
    if Circling[id] then return end
    local entity = entityData.spawned
    if not entity or not DoesEntityExist(entity) then return end
    Circling[id] = true

    CreateThread(function()
        local center = GetEntityCoords(entity)
        local angle = (index - 1) * ((math.pi * 2) / math.max(count, 1))
        while Circling[id] and entityData.spawned == entity and DoesEntityExist(entity) do
            local pos = Bridge.LA.Circle(angle, radius, center)
            FreezeEntityPosition(entity, false)
            SetEntityCoords(entity, pos.x, pos.y, pos.z, false, false, false, false)
            FreezeEntityPosition(entity, true)
            angle = angle + speed * GetFrameTime()
            Wait(0)
        end
        Circling[id] = nil
    end)
end

local function OnHolySpawn(entityData)
    local info = entityData.holyman or {}
    local config = PedistalConfig()

    if info.role == 'pedestal' then
        local bob = config.bob or {}
        StartBob(entityData, bob.speed or 0.5, bob.height or 0.1)
        if entityData.holyActive then
            StartParticles(entityData)
            StartMarkers(entityData)
        end
        return
    end

    if info.role == 'candle' then
        local candles = config.candles or {}
        if candles.collisions == false then
            SetEntityCollision(entityData.spawned, false, false)
        end
        StartCircle(entityData, candles.radius or 2.0, candles.speed or 1.25, info.index or 1, info.count or 1)
    end
end

local function OnHolyRemove(entityData)
    Bobbing[entityData.id] = nil
    Circling[entityData.id] = nil
    StopParticles(entityData)
    StopMarkers(entityData)
    if entityData.spawned and DoesEntityExist(entityData.spawned) then
        Bridge.Target.RemoveLocalEntity(entityData.spawned)
    end
end

Bridge.Entity.SetOnCreate('holyman', function(entityData)
    local info = entityData.holyman
    if type(info) ~= 'table' then return entityData end

    entityData.OnSpawn = OnHolySpawn
    entityData.OnRemove = OnHolyRemove

    if info.role == 'pedestal' then
        local ritualCfg = Config.ReviveRitual or {}
        local player = GetPlayerFromServerId(info.target)
        local playerName = player ~= -1 and GetPlayerName(player) or 'Player'
        local label = ritualCfg.Label and string.format(ritualCfg.Label, playerName) or 'Revive'

        entityData.targets = {
            {
                name = string.format('holyman-%s', entityData.id),
                label = label,
                icon = ritualCfg.Icon or 'fa-solid fa-cross',
                distance = 2.5,
                onSelect = function()
                    TriggerServerEvent('mrc-holyman:server:ParticipateInRitual', entityData.id, info.target)
                end
            }
        }

        -- Fired by Bridge.Entity.Set(id, { holyActive = true }) on the server.
        entityData.OnHolyActive = function(data, _, value)
            if not value then
                StopParticles(data)
                return StopMarkers(data)
            end
            StartParticles(data)
            StartMarkers(data)
        end
    end

    return entityData
end)

Bridge.Callback.Register("mrc-holyman:weaponDamageEvent", function(data)
    local ped = PlayerPedId()
    local players = GetActivePlayers()
    local lPlayerCoords = GetEntityCoords(ped)
    for _, playerId in pairs(players) do
        local playerPed = GetPlayerPed(playerId)
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


--- Opens a progress bar with a single attached prop.
local function OpenRitualProgress(options, cb)
    if Bridge.ProgressBar.GetResourceName() ~= 'ox_lib' then
        return Bridge.ProgressBar.Open(options, cb, true)
    end

    -- Bug in the bridge
    local anim = options.animation or {}
    local prop = options.prop or {}
    local disables = options.controlDisables or {}

    return Bridge.ProgressBar.Open({
        duration = options.duration,
        label = options.label,
        position = 'bottom',
        useWhileDead = options.useWhileDead,
        canCancel = options.canCancel,
        disable = {
            move = disables.disableMovement or disables.move,
            car = disables.disableCarMovement or disables.car,
            combat = disables.disableCombat or disables.combat,
            mouse = disables.disableMouse or disables.mouse,
        },
        anim = {
            dict = anim.animDict,
            clip = anim.anim,
            flag = anim.flags or anim.flag or 49,
        },
        prop = prop.model and {
            model = prop.model,
            bone = prop.bone,
            pos = prop.coords,
            rot = prop.rotation,
        },
    }, cb)
end

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

            OpenRitualProgress({
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
            end)
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
