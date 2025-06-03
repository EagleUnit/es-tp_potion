math.randomseed(GetGameTimer())

local lastPotionUse = 0

local function debugPrint(msg)
    if Config.Main.Debug then
        print(msg)
    end
end

RegisterNetEvent('es-tp_potion:client:usePotion', function()
    local currentTimeSec = GetGameTimer() / 1000
    local cooldown = Config.Potion.PotionCooldown or 15

    if currentTimeSec - lastPotionUse < cooldown then
        debugPrint("[POTION] Cooldown active, cannot use potion yet.")
        return
    end
    lastPotionUse = currentTimeSec
    debugPrint("[POTION] Potion usage started.")
    TriggerServerEvent('es-tp_potion:server:removePotion')

    local ped = PlayerPedId()
    local model = 'prop_shots_glass_cs'
    debugPrint("[POTION] Loading potion model:", model)

    RequestModel(model)
    while not HasModelLoaded(model) do Wait(10) end
    debugPrint("[POTION] Model loaded.")

    local potionProp = CreateObject(model, 0.0, 0.0, 0.0, true, true, true)
    SetEntityAsMissionEntity(potionProp, true, true)
    SetEntityCollision(potionProp, false, false)
    SetEntityVisible(potionProp, true, 0)
    AttachEntityToEntity(potionProp, ped, GetPedBoneIndex(ped, 18905),
        0.13, 0.03, 0.02,
        60.0, -130.0, -90.0,
        true, true, false, false, 2, true
    )
    debugPrint("[POTION] Potion object attached to player.")

    if Config.Potion.UseAnimations then
        local ed, ea = Config.Potion.Animations.EnterDrinkingAnim.dict, Config.Potion.Animations.EnterDrinkingAnim.anim
        local id, ia = Config.Potion.Animations.IdleDrinkingAnim.dict, Config.Potion.Animations.IdleDrinkingAnim.anim
        local xd, xa = Config.Potion.Animations.ExitDrinkingAnim.dict, Config.Potion.Animations.ExitDrinkingAnim.anim

        debugPrint("[POTION] Loading animation dictionaries...")
        RequestAnimDict(ed); RequestAnimDict(id); RequestAnimDict(xd)
        while not HasAnimDictLoaded(ed) or not HasAnimDictLoaded(id) or not HasAnimDictLoaded(xd) do Wait(10) end
        debugPrint("[POTION] Animation dictionaries loaded.")

        TaskPlayAnim(ped, ed, ea, 4.0, -4.0, -1, 49, 0, false, false, false)
        Wait(150)
        TaskPlayAnim(ped, id, ia, 4.0, -4.0, 1000, 49, 0, false, false, false)
        Wait(3000)
        TaskPlayAnim(ped, xd, xa, 4.0, -4.0, 1000, 49, 0, false, false, false)
        ClearPedTasks(ped)
        debugPrint("[POTION] Animation sequence played.")
    end

    DeleteEntity(potionProp)
    debugPrint("[POTION] Potion object deleted.")
    Teleport(ped)
end)

function Teleport(ped)
    if not DoesEntityExist(ped) or IsEntityDead(ped) then return end
    effectActive = true
    local pedCoords = GetEntityCoords(ped)
    local radius = Config.Potions.TeleportDistance or 60
    local myId = PlayerId()
    local nearbyPlayers = {}
    local nearbyPeds = {}

    local function findNearbyEntities()
        nearbyPlayers = {}
        nearbyPeds = {}
        for _, id in ipairs(GetActivePlayers()) do
            if id ~= myId then
                local playerPed = GetPlayerPed(id)
                if DoesEntityExist(playerPed) and not IsEntityDead(playerPed) then
                    local coords = GetEntityCoords(playerPed)
                    if #(coords - pedCoords) <= radius then
                        table.insert(nearbyPlayers, playerPed)
                    end
                end
            end
        end
        local handle, npc = FindFirstPed()
        local success
        repeat
            if DoesEntityExist(npc) and not IsPedAPlayer(npc) and not IsEntityDead(npc) then
                local npcCoords = GetEntityCoords(npc)
                if #(npcCoords - pedCoords) <= radius then
                    table.insert(nearbyPeds, npc)
                end
            end
            success, npc = FindNextPed(handle)
        until not success
        EndFindPed(handle)
    end

    local function doRandomTeleport()
        debugPrint("[POTION] Teleporting to a nearby place.")
        local offsetX = math.random(-radius * 100, radius * 100) / 100
        local offsetY = math.random(-radius * 100, radius * 100) / 100
        local newCoords = pedCoords + vector3(offsetX, offsetY, 0)
        local foundGround, groundZ = GetGroundZFor_3dCoord(newCoords.x, newCoords.y, newCoords.z + 50.0, false)
        if foundGround then
            newCoords = vector3(newCoords.x, newCoords.y, groundZ)
        end
        SetEntityCoordsNoOffset(ped, newCoords.x, newCoords.y, newCoords.z, false, false, false)
    end

    local function teleportToNPCOrPlayer(targetPed, ped)
        local pedCoords = GetEntityCoords(ped)
        local npcCoords = GetEntityCoords(targetPed)
        if IsPedInAnyVehicle(targetPed, false) and advCfg.Teleport.CarSwap then
            local veh = GetVehiclePedIsIn(targetPed, false)
            local seat = -1

            ClearPedTasksImmediately(targetPed)
            TaskLeaveVehicle(targetPed, veh, 4160)
            Wait(300)

            TaskWarpPedIntoVehicle(ped, veh, seat)
            SetEntityCoordsNoOffset(targetPed, pedCoords.x, pedCoords.y, pedCoords.z, false, false, false)
            debugPrint("[POTION] Swapped and stole their vehicle")
        else
            ClearPedTasksImmediately(targetPed)
            Wait(100)
            SetEntityCoordsNoOffset(targetPed, pedCoords.x, pedCoords.y, pedCoords.z, false, false, false)
            Wait(100)
            SetEntityCoordsNoOffset(ped, npcCoords.x, npcCoords.y, npcCoords.z, false, false, false)
            debugPrint("[POTION] Swapped places with a nearby ped")
        end
    end

    if Config.Potions.Effects.Teleport and Config.Potions.TeleportSwap then
        local roll = math.random(1, 100)
        if roll <= (Config.Potions.SwapChance or 50) then
            findNearbyEntities()
            if Config.Potions.SwapRealPlayers and #nearbyPlayers > 0 then
                local targetPed = nearbyPlayers[math.random(#nearbyPlayers)]
                local targetServerId = GetPlayerServerId(NetworkGetEntityOwner(targetPed))
                local targetCoords = GetEntityCoords(targetPed)
                TriggerServerEvent('es-tp_potion:server:swapPlayers', targetServerId, pedCoords, targetCoords)
                effectActive = false
                return
            elseif #nearbyPeds > 0 then
                teleportToNPCOrPlayer(nearbyPeds[math.random(#nearbyPeds)], PlayerPedId())
                effectActive = false
                return
            end
        end
        doRandomTeleport()
    elseif Config.Potions.Effects.Teleport then
        doRandomTeleport()
    elseif Config.Potions.TeleportSwap then
        findNearbyEntities()
        if Config.Potions.SwapRealPlayers and #nearbyPlayers > 0 then
            local targetPed = nearbyPlayers[math.random(#nearbyPlayers)]
            local targetServerId = GetPlayerServerId(NetworkGetEntityOwner(targetPed))
            local targetCoords = GetEntityCoords(targetPed)
            TriggerServerEvent('es-tp_potion:server:swapPlayers', targetServerId, pedCoords, targetCoords)
        elseif #nearbyPeds > 0 then
            teleportToNPCOrPlayer(nearbyPeds[math.random(#nearbyPeds)], PlayerPedId())
        end
    end

    effectActive = false
end

RegisterNetEvent('es-tp_potion:client:teleportTo', function(coords)
    local ped = PlayerPedId()
    SetEntityCoordsNoOffset(ped, coords.x, coords.y, coords.z, false, false, false)
    debugPrint(string.format("[POTION] Teleport received from server: x=%.2f, y=%.2f, z=%.2f", coords.x, coords.y, coords.z))
end)