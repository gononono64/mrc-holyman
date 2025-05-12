
local Pedistals = {}

function StartRitual(id, targetCoords)
    local pedistal = Pedistals[id]
    if not pedistal then return end
    Bridge.Marker.CreateBulk(pedistal.markers)
    Bridge.Particle.CreateBulk(pedistal.particles)
  
    TriggerClientEvent("mrc-holyman:client:StartRitual", -1, Pedistals[id])
end

function StopRitual(id)   
    RemovePedistal(id)
    Pedistals[id] = nil
    return true
end

function CreatePedistal(id, target, coords)
    local config = Config.ReviveRitual
    Bridge.ServerEntity.Create(id, 'object', config.Pedistal.model, coords, config.Pedistal.rotationOffset)
    Bridge.ServerEntity.TriggerActions(id, {   
        {name = 'Freeze', params = {true}},
        {name = 'BobUpAndDown', params = {0.5, 0.1}},
        {name = 'Target', params = {'pedestal', target}},
        {name = 'Track', params = {'pedestal'}},
    }, coords)

    local data = Pedistals[id] or {}
    data.propIds = data.propIds or {}
    data.markers = data.markers or {}
    data.particles = data.particles or {}

    
    for i = 1, 5 do 
        local model = i==5 and 'v_prop_floatcandle' or 'v_res_fa_candle0'..i
        local propId = id..i
        Bridge.ServerEntity.Create(propId, 'object', model, coords - vector3(0.0, 0.0, 0.25), vector3(0.0, 0.0, 0.0), {freeze = true})
        Bridge.ServerEntity.TriggerActions(propId, {     
            {name = 'Collisions', params = {false, false}},           
            {name = 'Freeze', params = {true}},
            {name = 'Collisions', params = {true}},    
            {name = 'Circle', params = {2.0, 1.25}},
            {name = 'Track', params = {'pedestal'}},
        }, coords)
        table.insert(data.propIds, propId)
    end
    
    local makerConfig = Bridge.Tables.DeepClone(config.Pedistal.markers)
    for k, v in pairs(makerConfig) do
        if type(v) == "table" then
            local derpa = string.format("%s-:Marker-%s", id, k)
            v.id = derpa
            v.position =  coords + (v.offset or vector3(0.0, 0.0, 0.0))
            v.offset = nil
            v.type = v.type or 1
            v.size = v.size or vector3(0.5, 0.5, 0.5)
            v.color = v.color or vector3(255, 0, 0)
            v.alpha = v.alpha or 150
            v.bobUpAndDown = v.bobUpAndDown or true
            v.drawDistance = v.drawDistance or 50.0
            table.insert(data.markers, v)
        end            
    end
    local particleConfig = Bridge.Tables.DeepClone(config.Pedistal.particles)
    for k, v in pairs(particleConfig) do
        if type(v) == "table" then
            v.id = string.format("%s-:Particle-%s", id, k)
            v.position = coords + (v.offset or vector3(0.0, 0.0, 0.0))
            v.offset = nil
            v.rotation = data.rotation or vector3(0, 0, 0)      
            table.insert(data.particles, v)
        end            
    end
    Pedistals[id] = data
    return id
end

function RemovePedistal(id)
    local pedestal = Pedistals[id]
    if not pedestal then return end
    for k, v in pairs(pedestal.propIds) do
        Bridge.ServerEntity.Delete(v)
    end
    Bridge.ServerEntity.Delete(id)

    Bridge.Marker.RemoveBulk(pedestal.markers)
    Bridge.Particle.RemoveBulk(pedestal.particles)
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

        Pedistals[id] = Pedistals[id] or {}
        Pedistals[id].target = target
        Pedistals[id].src = src
        Pedistals[id].id = id
        Pedistals[id].cultists = {}
        Pedistals[id].cultists[tostring(src)] = true
        Pedistals[id].count = 1
        if config.ParticipantsNeeded <= 1 then
            StartRitual(id, coords)            
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
    local participantsNeeded = config.ParticipantsNeeded
    if pedestal.count < participantsNeeded then return end
    TriggerClientEvent("mrc-holyman:client:StartRitual", -1, pedestal)
     -- Define the marker's properties, using playerCoords as the base position
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
