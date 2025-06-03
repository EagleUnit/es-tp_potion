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

RegisterNetEvent('es-tp_potion:server:swapPlayers', function(targetServerId, sourceCoords, targetCoords)
    local src = source
    if not (sourceCoords and sourceCoords.x and sourceCoords.y and sourceCoords.z) then return end
    if not (targetCoords and targetCoords.x and targetCoords.y and targetCoords.z) then return end

    local maxDistance = Config.Potion.TeleportDistance or 60
    local dx = sourceCoords.x - targetCoords.x
    local dy = sourceCoords.y - targetCoords.y
    local dz = sourceCoords.z - targetCoords.z
    local distance = math.sqrt(dx*dx + dy*dy + dz*dz)

    if distance <= maxDistance then
        TriggerClientEvent('es-tp_potion:client:teleportTo', targetServerId, sourceCoords)
        TriggerClientEvent('es-tp_potion:client:teleportTo', src, targetCoords)
        debugPrint(string.format("[POTION] Swapping places between %d and %d", src, targetServerId))
    else
        debugPrint(string.format("[POTION] Swap request denied, players too far apart: distance = %.2f", distance))
    end
end)

local function CheckVersion()
    if Config.Main.CheckForUpdates then
        PerformHttpRequest('https://raw.githubusercontent.com/EagleUnit/eaglescriptsversions/main/tp_potion.txt', function(err, newestVersion, headers)
            if not newestVersion then 
                print("[es-tp_potion] ^2Currently unable to run a version check.^7") 
                return 
            end
            local currentVersion = GetResourceMetadata(GetCurrentResourceName(), 'version') or "unknown"
            local formattedCurrent = "^3"..currentVersion:gsub("%.", "^7.^3").."^7"
            local trimmedNewest = newestVersion:match("^%s*(.-)%s*$") or ""
            local formattedNewest = "^3"..trimmedNewest:gsub("%.", "^7.^3").."^7"

            if formattedNewest == formattedCurrent then
                print(string.format('[es-tp_potion] ^2You are running the latest version of es-tp_potion!^7 (%s)', formattedCurrent))
            else
                print(string.format('[es-tp_potion] ^1You are currently running an outdated version of es-tp_potion (Current Version: ^7%s^1, Newest Version: ^7%s^1). Please download the newest version at https://github.com/EagleUnit/es-tp_potion^7!', formattedCurrent, formattedNewest))
            end
        end)
    end
end
CheckVersion()