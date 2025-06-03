Config = {}

Config.Main = {
    Framework = 'qb',          -- 'qb' or 'esx'
    Inventory = 'ox',          -- 'qb' or 'esx' or 'ox'
    Debug = true,              -- Prints debug statements to the f8 console
    CheckForUpdates = true     -- Recommended to keep true to ensure your updated.
}

Config.Potion = {
    Teleport = true,            -- Enable the teleport
    RemoveAfterUse = true,      -- Remove the potion after using it. If false, keeps potion after use.
    PotionCooldown = 5,        -- Time before a player can use another potion (in seconds)
    TeleportDistance = 100,      -- How far you can teleport in metres. (1-xx randomized)
    TeleportSwap = true,        -- Make it so it can make you swap places with a nearby npc
    SwapRealPlayers = true,     -- If teleport swap is enabled, it will swap your place with a real player. If no players are nearby, it will swap with an npc
    CarSwap = true,             -- If the player whos swapping places with a ped/real player and their in a car, take them out of the car and put you in the car.
    SwapChance = 33,           -- The chance that it will make you swap places with an npc or player
    UseAnimations = true,       -- Use animations for drinking the potion (Recommended)
    Animations = {
        EnterDrinkingAnim = {dict = 'mp_player_intdrink', anim = 'intro_bottle_fp'},
        IdleDrinkingAnim = {dict = 'mp_player_intdrink', anim = 'loop_bottle'},
        ExitDrinkingAnim = {dict = 'mp_player_intdrink', anim = 'outro_bottle_fp'}
    }
}