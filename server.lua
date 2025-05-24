local QBCore, ESX = nil, nil
if Config.Main.Framework == 'qb' then
    QBCore = exports['qb-core']:GetCoreObject()
elseif Config.Main.Framework == 'esx' then
    ESX = exports["es_extended"]:getSharedObject()
end

if Config.Main.Framework == 'qb' then
    QBCore.Functions.CreateUseableItem('potion', function(src)
        TriggerClientEvent('es-tp_potion:client:usePotion', src)
    end)
elseif Config.Main.Framework == 'esx' then
    ESX.RegisterUsableItem('potion', function(src)
        TriggerClientEvent('es-tp_potion:client:usePotion', src)
    end)
end

local function debugPrint(msg)
    if Config.Main.Debug then
        print(msg)
    end
end

RegisterNetEvent('es-tp_potion:server:removePotion', function()
    local src = source
    if not Config.Potion.RemoveAfterUse then return end

    if Config.Main.Inventory == 'qb' then
        local Player = QBCore.Functions.GetPlayer(src)
        if Player then
            Player.Functions.RemoveItem('potion', 1)
            debugPrint(string.format("[POTION] Removed 1 potion from player %d (QBCore)", src))
        end
    elseif Config.Main.Inventory == 'esx' then
        local xPlayer = ESX.GetPlayerFromId(src)
        if xPlayer then
            xPlayer.removeInventoryItem('potion', 1)
            debugPrint(string.format("[POTION] Removed 1 potion from player %d (ESX)", src))
        end
    elseif Config.Main.Inventory == 'ox' then
        exports.ox_inventory:RemoveItem(src, 'potion', 1)
        debugPrint(string.format("[POTION] Removed 1 potion from player %d (OX)", src))
    end
end)

RegisterNetEvent('es-potions:server:swapPlayers', function(targetServerId, sourceCoords, targetCoords)
    local src = source
    if not (sourceCoords and sourceCoords.x and sourceCoords.y and sourceCoords.z) then return end
    if not (targetCoords and targetCoords.x and targetCoords.y and targetCoords.z) then return end

    local maxDistance = Config.Potions.TeleportDistance or 60
    local dx = sourceCoords.x - targetCoords.x
    local dy = sourceCoords.y - targetCoords.y
    local dz = sourceCoords.z - targetCoords.z
    local distance = math.sqrt(dx*dx + dy*dy + dz*dz)

    if distance <= maxDistance then
        TriggerClientEvent('es-potions:client:teleportTo', targetServerId, sourceCoords)
        TriggerClientEvent('es-potions:client:teleportTo', src, targetCoords)
        debugPrint("[POTION] Swapping places with ID: " .. targetServerId)
    end
end)