
local Pedistals = {}

local function CandleId(id, index)
    return string.format("%s-:Candle-%s", id, index)
end

function StartRitual(id)
    local pedistal = Pedistals[id]
    if not pedistal then return end

    Bridge.Entity.Set(id, { holyActive = true })
    for _, propId in pairs(pedistal.propIds or {}) do
        Bridge.Entity.Set(propId, { holyActive = true })
    end
    TriggerClientEvent("mrc-holyman:client:StartRitual", -1, pedistal)
end

function StopRitual(id)
    RemovePedistal(id)
    return true
end

function CreatePedistal(id, target, coords)
    local config = Config.ReviveRitual
    local pedistalCfg = config.Pedistal
    local spawnDistance = pedistalCfg.spawnDistance or 100.0

    local candlesCfg = pedistalCfg.candles or {}
    local models = candlesCfg.models or {}
    local candleOffset = candlesCfg.offset or vector3(0.0, 0.0, -0.25)
    local launchCfg = candlesCfg.launch or {}
    local delayMin = launchCfg.delayMin or 250
    local delayMax = math.max(launchCfg.delayMax or 2500, delayMin)

    local data = Pedistals[id] or {}
    data.propIds = {}
    data.coords = coords

    local entities = {
        {
            id = id,
            entityType = 'object',
            model = pedistalCfg.model,
            coords = coords,
            rotation = pedistalCfg.rotationOffset or vector3(0.0, 0.0, 0.0),
            spawnDistance = spawnDistance,
            freeze = true,
            holyman = { role = 'pedestal', target = target },
        }
    }

    for k, v in ipairs(models) do
        local propId = CandleId(id, k)
        entities[#entities + 1] = {
            id = propId,
            entityType = 'object',
            model = v,
            coords = coords + candleOffset,
            rotation = vector3(0.0, 0.0, 0.0),
            spawnDistance = spawnDistance,
            freeze = true,
            holyman = { role = 'candle', index = k, count = #models, origin = coords, delay = math.random(delayMin, delayMax) },
        }
        table.insert(data.propIds, propId)
    end

    -- One CreateEntities event for the pedestal and every candle, instead of one per prop.
    Bridge.Entity.CreateBulk(entities)

    Pedistals[id] = data
    return id
end

function RemovePedistal(id)
    local pedistal = Pedistals[id]
    if not pedistal then return end

    for _, propId in pairs(pedistal.propIds or {}) do
        Bridge.Entity.Destroy(propId)
    end
    Bridge.Entity.Destroy(id)

    Pedistals[id] = nil
end

AddEventHandler("weaponDamageEvent", function(src, data)
    src = tonumber(src)
    local player = GetPlayerPed(src)
    local playerWeapon = GetSelectedPedWeapon(player)
    if playerWeapon ~= Config.WeaponName then return end

    CancelEvent()
    local netId = data.hitGlobalId
    local target = NetworkGetEntityOwner(NetworkGetEntityFromNetworkId(netId))
    if not target then return end
    local targetPed = GetPlayerPed(target)
    local health = GetEntityHealth(targetPed)
    local maxHealth = GetEntityMaxHealth(targetPed)

    local targetIsDead = Bridge.Framework.GetIsPlayerDead(target)

    if targetIsDead then
        local config = Config.ReviveRitual
        local id = string.format("holy-pedestal-%s", src)
        if Pedistals[id] then return end
        if not Bridge.Framework.RemoveAccountBalance(src, "cash", config.Cost) then return end

        local rotation = GetEntityRotation(targetPed, 0)
        local offset = config.Pedistal.offset
        local rawcoords = GetEntityCoords(targetPed)
        local coords = Bridge.Math.GetOffsetFromMatrix(rawcoords, rotation, offset)
        CreatePedistal(id, target, coords)

        Pedistals[id].target = target
        Pedistals[id].src = src
        Pedistals[id].id = id
        Pedistals[id].cultists = {}
        Pedistals[id].cultists[tostring(src)] = true
        Pedistals[id].count = 1
        if config.ParticipantsNeeded <= 1 then
            StartRitual(id)
        end
        Bridge.Notify.SendNotify(src, "You have placed a holy pedestal", "success")
        return
    end

    if health >= maxHealth then return end
    if not Bridge.Framework.RemoveAccountBalance(src, "cash", Config.Healing.Cost) then return end
    Bridge.Callback.Trigger("mrc-holyman:weaponDamageEvent", target)
end)

RegisterNetEvent("mrc-holyman:server:ParticipateInRitual", function(id, target)
    local pedestal = Pedistals[id]
    if not pedestal then return end

    local src = source
    local ped = GetPlayerPed(src)
    local targetPed = GetPlayerPed(pedestal.target)
    local pedCoords = GetEntityCoords(ped)
    local targetCoords = GetEntityCoords(targetPed)
    local distance = #(targetCoords - pedCoords)
    if distance > 5.0 then return Bridge.Notify.SendNotify(src, "You are too far away", "error") end

    local strsrc = tostring(src)
    if pedestal.cultists[strsrc] then
        Bridge.Notify.SendNotify(src, "You are already participating in the ritual", "error")
        return
    end
    pedestal.cultists[strsrc] = true
    pedestal.count = pedestal.count + 1

    local config = Config.ReviveRitual
    if pedestal.count < config.ParticipantsNeeded then return end
    StartRitual(id)
end)

RegisterNetEvent('mrc-holyman:server:RitualDone', function(id)
    local src = source
    local pedestal = Pedistals[id]
    if not pedestal then return end
    local isPriest = pedestal.src == src
    local isCultist = pedestal.cultists[tostring(src)]
    if isPriest or isCultist then
        return StopRitual(id)
    end
    local target = pedestal.target
    if not target or src ~= target then return end
    Bridge.Framework.RevivePlayer(target)
    StopRitual(id)
end)

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    local ids = {}
    for id in pairs(Pedistals) do table.insert(ids, id) end
    for _, id in pairs(ids) do RemovePedistal(id) end
end)
