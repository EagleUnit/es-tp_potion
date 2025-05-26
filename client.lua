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

    if not DoesEntityExist(ped) or IsEntityDead(ped) then return end
    local pedCoords = GetEntityCoords(ped)
    local radius = Config.Potion.TeleportDistance or 60
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
        newCoords = vector3(newCoords.x, newCoords.y, foundGround and groundZ or newCoords.z)
        SetEntityCoordsNoOffset(ped, newCoords.x, newCoords.y, newCoords.z, false, false, false)
    end

    if Config.Potion.Teleport and Config.Potion.TeleportSwap then
        local roll = math.random(1, 100)
        if roll <= (Config.Potion.SwapChance or 50) then
            findNearbyEntities()
            if Config.Potion.SwapRealPlayers and #nearbyPlayers > 0 then
                debugPrint("[POTION] Attempting to swap places with a nearby player...")
                local targetPed = nearbyPlayers[math.random(1, #nearbyPlayers)]
                local targetServerId = GetPlayerServerId(NetworkGetEntityOwner(targetPed))
                local targetCoords = GetEntityCoords(targetPed)
                TriggerServerEvent('es-potions:server:swapPlayers', targetServerId, pedCoords, targetCoords)
                return
            elseif #nearbyPeds > 0 then
                debugPrint("[POTION] Swapping places with a nearby NPC.")
                local npc = nearbyPeds[math.random(1, #nearbyPeds)]
                local npcCoords = GetEntityCoords(npc)
                SetEntityCoordsNoOffset(npc, pedCoords.x, pedCoords.y, pedCoords.z, false, false, false)
                Wait(100)
                SetEntityCoordsNoOffset(ped, npcCoords.x, npcCoords.y, npcCoords.z, false, false, false)
                return
            end
        end
        doRandomTeleport()
    elseif Config.Potion.Teleport then
        doRandomTeleport()
    elseif Config.Potion.TeleportSwap then
        findNearbyEntities()
        if Config.Potion.SwapRealPlayers and #nearbyPlayers > 0 then
            local targetPed = nearbyPlayers[math.random(1, #nearbyPlayers)]
            local targetServerId = GetPlayerServerId(NetworkGetEntityOwner(targetPed))
            local targetCoords = GetEntityCoords(targetPed)
            TriggerServerEvent('es-potions:server:swapPlayers', targetServerId, pedCoords, targetCoords)
        elseif #nearbyPeds > 0 then
            debugPrint("[POTION] Swapping places with a nearby NPC.")
            local npc = nearbyPeds[math.random(1, #nearbyPeds)]
            local npcCoords = GetEntityCoords(npc)
            SetEntityCoordsNoOffset(npc, pedCoords.x, pedCoords.y, pedCoords.z, false, false, false)
            Wait(100)
            SetEntityCoordsNoOffset(ped, npcCoords.x, npcCoords.y, npcCoords.z, false, false, false)
        end
    end
end)

RegisterNetEvent('es-potions:client:teleportTo', function(coords)
    local ped = PlayerPedId()
    SetEntityCoordsNoOffset(ped, coords.x, coords.y, coords.z, false, false, false)
    debugPrint(string.format("[POTION] Teleport received from server: x=%.2f, y=%.2f, z=%.2f", coords.x, coords.y, coords.z))
end)