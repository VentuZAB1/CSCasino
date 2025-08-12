-- CS Casino Client Main File
-- QBox Framework Integration
local isUIOpen = false
local currentCaseOpening = false

-- NUI Callbacks and Events

-- Register NUI callback for closing UI
RegisterNUICallback('closeUI', function(data, cb)
    SetNuiFocus(false, false)
    isUIOpen = false
    
    -- Stop monitoring cooldown status
    stopCooldownMonitoring()
    
    cb('ok')
end)

-- Register NUI callback for opening case
RegisterNUICallback('openCase', function(data, cb)
    if currentCaseOpening then
        cb({success = false, message = 'Already opening a case!'})
        return
    end
    
    currentCaseOpening = true
    TriggerServerEvent('cs-casino:server:openCase', data.caseType)
    cb({success = true})
end)

-- Register NUI callback for selling item
RegisterNUICallback('sellItem', function(data, cb)
    TriggerServerEvent('cs-casino:server:sellItem', data.itemName, data.amount)
    cb({success = true})
end)

-- Register NUI callback for getting sellable items
RegisterNUICallback('getSellableItems', function(data, cb)
    TriggerServerEvent('cs-casino:server:getSellableItems')
    cb({success = true})
end)

-- Register NUI callback for getting player stats
RegisterNUICallback('getPlayerStats', function(data, cb)
    TriggerServerEvent('cs-casino:server:getStats')
    cb({success = true})
end)

-- Register NUI callback for collecting item
RegisterNUICallback('collectItem', function(data, cb)
    TriggerServerEvent('cs-casino:server:collectItem', data)
    cb({success = true})
end)

-- Register NUI callback for getting pending items
RegisterNUICallback('getPendingItems', function(data, cb)
    TriggerServerEvent('cs-casino:server:getPendingItems')
    cb({success = true})
end)

-- Register NUI callback for keeping pending item
RegisterNUICallback('keepPendingItem', function(data, cb)
    TriggerServerEvent('cs-casino:server:keepPendingItem', data)
    cb({success = true})
end)

-- Register NUI callback for selling pending item
RegisterNUICallback('sellPendingItem', function(data, cb)
    TriggerServerEvent('cs-casino:server:sellPendingItem', data)
    cb({success = true})
end)

-- Handle cooldown notification request from UI
RegisterNUICallback('showCooldownNotification', function(data, cb)
    local remainingTime = data.remainingTime or 1
    
    -- Show cooldown notification
    local cooldownMessage = Config.Titles.notifications.cooldownActive:gsub('{time}', remainingTime == 1 and (remainingTime .. ' second') or (remainingTime .. ' seconds'))
    exports.ox_lib:notify({
        type = 'error',
        description = cooldownMessage,
        duration = 3000
    })
    
    cb('ok')
end)

-- Start cooldown monitoring thread when UI opens
local cooldownMonitorActive = false

-- Function to start monitoring cooldown status
function startCooldownMonitoring()
    if cooldownMonitorActive then return end
    cooldownMonitorActive = true
    
    CreateThread(function()
        while cooldownMonitorActive do
            if isCurrentlyOnCooldown() then
                local currentTime = GetGameTimer()
                local remainingMs = (cooldownEndTime or 0) - currentTime
                local remainingSeconds = math.ceil(remainingMs / 1000)
                
                if remainingSeconds <= 0 then
                    remainingSeconds = 0
                    isOnCooldown = false
                    cooldownEndTime = 0
                end
                
                -- Send cooldown status to UI
                SendNUIMessage({
                    type = 'cooldownStatus',
                    isOnCooldown = true,
                    remainingTime = remainingSeconds
                })
            else
                -- Send no cooldown status to UI
                SendNUIMessage({
                    type = 'cooldownStatus',
                    isOnCooldown = false,
                    remainingTime = 0
                })
            end
            
            Wait(1000) -- Update every second
        end
    end)
end

-- Function to stop monitoring cooldown status
function stopCooldownMonitoring()
    cooldownMonitorActive = false
end

-- Server Events

-- Event: Open UI
RegisterNetEvent('cs-casino:client:openUI', function(data)
    print('^2[CS Casino] ^7Opening UI for player')
    if isUIOpen then 
        print('^3[CS Casino] ^7UI already open, ignoring')
        return 
    end
    
    isUIOpen = true
    SetNuiFocus(true, true)
    
    SendNUIMessage({
        type = 'openCasino',
        data = data
    })
    
    -- Start monitoring cooldown status
    startCooldownMonitoring()
    
    print('^2[CS Casino] ^7UI opened successfully')
end)

-- Event: Case opened result
RegisterNetEvent('cs-casino:client:caseOpened', function(result)
    currentCaseOpening = false
    
    SendNUIMessage({
        type = 'caseOpened',
        data = result
    })
    
    -- Play success sound
    PlaySoundFrontend(-1, "WAYPOINT_SET", "HUD_FRONTEND_DEFAULT_SOUNDSET", false)
end)

-- Event: Update money display
RegisterNetEvent('cs-casino:client:updateMoney', function(newMoney)
    SendNUIMessage({
        type = 'updateMoney',
        data = {money = newMoney}
    })
end)

-- Event: Receive player stats
RegisterNetEvent('cs-casino:client:receiveStats', function(stats)
    SendNUIMessage({
        type = 'playerStats',
        data = stats
    })
end)

-- Event: Receive sellable items
RegisterNetEvent('cs-casino:client:receiveSellableItems', function(items)
    SendNUIMessage({
        type = 'sellableItems',
        data = {items = items}
    })
end)

-- Event: Receive pending items
RegisterNetEvent('cs-casino:client:pendingItems', function(data)
    SendNUIMessage({
        type = 'pendingItems',
        data = data
    })
end)

-- Debug helper function
local function debugPrint(category, message)
    if not Config.Debug.enabled then return end
    if not Config.Debug.client[category] then return end
    
    print(string.format('^2[CS Casino Debug/%s] ^7%s', category, message))
end

-- Casino Interaction System
local nearCasino = false
local currentLocation = nil
local nearNPC = false
local currentNPC = nil

-- Helper function to get resolved label from config
local function GetResolvedLabel(labelRef)
    if not labelRef then return 'Open Casino' end
    
    -- If it's a direct reference to Config.Titles
    if labelRef == 'openLabel' then
        return Config.Titles.openLabel
    elseif labelRef == 'accessLabel' then
        return Config.Titles.accessLabel
    end
    
    -- If it's already a resolved string, return it
    return labelRef
end

-- Helper function to get resolved blip label
local function GetResolvedBlipLabel(blipLabelRef)
    if not blipLabelRef then return 'Casino' end
    
    if blipLabelRef == 'mainCasino' then
        return Config.Titles.blipLabels.mainCasino
    elseif blipLabelRef == 'casinoEntrance' then
        return Config.Titles.blipLabels.casinoEntrance
    elseif blipLabelRef == 'casinoInterior' then
        return Config.Titles.blipLabels.casinoInterior
    end
    
    return blipLabelRef
end
local blips = {}

-- Casino Blips Creation
local function CreateCasinoBlips()
    for i, location in pairs(Config.CasinoLocations) do
        if location.useBlip then
            local blip = AddBlipForCoord(location.coords.x, location.coords.y, location.coords.z)
            SetBlipSprite(blip, location.blipSprite)
            SetBlipColour(blip, location.blipColor)
            SetBlipScale(blip, location.blipScale)
            SetBlipAsShortRange(blip, true)
            BeginTextCommandSetBlipName('STRING')
            AddTextComponentString(GetResolvedBlipLabel(location.blipLabel))
            EndTextCommandSetBlipName(blip)
            table.insert(blips, blip)
        end
    end
end

-- Casino Interaction Zones Setup
local function SetupCasinoInteractions()
    if Config.InteractionType == 'ox_target' or Config.InteractionType == 'both' then
        for i, location in pairs(Config.CasinoLocations) do
            -- Add ox_target zone
            exports.ox_target:addSphereZone({
                coords = location.coords,
                radius = location.radius,
                debug = Config.Debug.enabled and Config.Debug.client.interactions,
                options = {
                    {
                        name = 'cs_casino_zone_' .. i,
                        icon = location.icon,
                        label = GetResolvedLabel(location.label),
                        distance = location.radius,
                                            onSelect = function()
                        openCasinoWithChecks()
                    end
                    }
                }
            })
        end
    end
end

-- Casino Distance Check for ox_lib TextUI
local distanceCheckActive = false
local function CheckCasinoDistance()
    if (Config.InteractionType == 'ox_lib' or Config.InteractionType == 'both') and not distanceCheckActive then
        distanceCheckActive = true
        debugPrint('interactions', 'Starting distance checking thread')
        CreateThread(function()
            while true do
                local playerPed = PlayerPedId()
                local playerCoords = GetEntityCoords(playerPed)
                local wasNearCasino = nearCasino
                local wasNearNPC = nearNPC
                nearCasino = false
                nearNPC = false
                currentLocation = nil
                currentNPC = nil
                
                -- Check distance to casino locations
                for i, location in pairs(Config.CasinoLocations) do
                    local distance = #(playerCoords - location.coords)
                    if distance <= location.radius then
                        nearCasino = true
                        currentLocation = location
                        break
                    end
                end
                
                -- Check distance to NPCs
                for i, npcData in pairs(Config.NPCLocations) do
                    local npcCoords = vector3(npcData.coords.x, npcData.coords.y, npcData.coords.z)
                    local distance = #(playerCoords - npcCoords)
                    if distance <= 2.0 then
                        nearNPC = true
                        currentNPC = npcData
                        break
                    end
                end
                
                -- Show/Hide TextUI based on proximity
                if nearCasino and not wasNearCasino and currentLocation then
                    exports.ox_lib:showTextUI('[E] ' .. GetResolvedLabel(currentLocation.label), {
                        position = 'left-center',
                        icon = currentLocation.icon or 'fas fa-dice',
                        style = {
                            borderRadius = 8,
                            backgroundColor = 'rgba(139, 69, 193, 0.9)',
                            color = 'white'
                        }
                    })
                elseif nearNPC and not wasNearNPC and currentNPC then
                    exports.ox_lib:showTextUI('[E] ' .. GetResolvedLabel('openLabel'), {
                        position = 'left-center',
                        icon = 'fas fa-dice',
                        style = {
                            borderRadius = 8,
                            backgroundColor = 'rgba(139, 69, 193, 0.9)',
                            color = 'white'
                        }
                    })
                elseif (not nearCasino and wasNearCasino) or (not nearNPC and wasNearNPC) then
                    exports.ox_lib:hideTextUI()
                end
                
                Wait(100)
            end
        end)
    end
end

-- Key Press Handler for E key
local keyHandlerActive = false
local function HandleKeyPress()
    if (Config.InteractionType == 'ox_lib' or Config.InteractionType == 'both') and not keyHandlerActive then
        keyHandlerActive = true
        debugPrint('interactions', 'Starting key press handler thread')
        CreateThread(function()
            while true do
                if nearCasino or nearNPC then
                    if IsControlJustPressed(0, 38) then -- E key
                        openCasinoWithChecks()
                    end
                end
                Wait(0)
            end
        end)
    end
end

-- NPC Storage for cleanup
local spawnedNPCs = {}

-- NPC Interaction (if NPCs are configured)
local function CreateCasinoNPCs()
    debugPrint('npcs', 'Starting NPC creation process...')
    
    if not Config.NPCLocations or #Config.NPCLocations == 0 then
        debugPrint('npcs', 'No NPC locations configured, skipping NPC creation')
        return
    end
    
    for i, npcData in pairs(Config.NPCLocations) do
        debugPrint('npcs', 'Creating NPC ' .. i .. ' with model: ' .. npcData.model)
        debugPrint('npcs', 'NPC coordinates: ' .. tostring(npcData.coords))
        
        -- Validate model hash
        local modelHash = GetHashKey(npcData.model)
        if not IsModelValid(modelHash) then
            debugPrint('npcs', 'ERROR: Invalid model hash for ' .. npcData.model)
            print('^1[CS Casino] ^7ERROR: Invalid NPC model: ' .. npcData.model)
            goto continue
        end
        
        -- Request model with timeout
        RequestModel(modelHash)
        local attempts = 0
        local maxAttempts = 20 -- 10 seconds timeout
        
        while not HasModelLoaded(modelHash) and attempts < maxAttempts do
            Wait(500)
            attempts = attempts + 1
            debugPrint('npcs', 'Waiting for model to load... attempt ' .. attempts .. '/' .. maxAttempts)
        end
        
        if not HasModelLoaded(modelHash) then
            debugPrint('npcs', 'ERROR: Failed to load model ' .. npcData.model .. ' after ' .. maxAttempts .. ' attempts')
            print('^1[CS Casino] ^7ERROR: Failed to load NPC model: ' .. npcData.model)
            goto continue
        end
        
        debugPrint('npcs', 'Model loaded successfully, creating ped...')
        
        -- Create the NPC
        local npc = CreatePed(4, modelHash, npcData.coords.x, npcData.coords.y, npcData.coords.z - 1.0, npcData.coords.w, false, true)
        
        if not DoesEntityExist(npc) then
            debugPrint('npcs', 'ERROR: Failed to create NPC entity')
            print('^1[CS Casino] ^7ERROR: Failed to create NPC entity')
            goto continue
        end
        
        -- Store NPC for cleanup
        table.insert(spawnedNPCs, npc)
        
        -- Configure NPC
        SetEntityHeading(npc, npcData.coords.w)
        FreezeEntityPosition(npc, true)
        SetEntityInvincible(npc, true)
        SetBlockingOfNonTemporaryEvents(npc, true)
        SetModelAsNoLongerNeeded(modelHash)
        
        debugPrint('npcs', 'NPC entity configured successfully')
        
        -- Apply scenario if specified
        if npcData.scenario then
            debugPrint('npcs', 'Applying scenario: ' .. npcData.scenario)
            TaskStartScenarioInPlace(npc, npcData.scenario, 0, true)
        end
        
        -- Create interaction point based on Config.InteractionType
        if Config.InteractionType == 'ox_target' or Config.InteractionType == 'both' then
            debugPrint('npcs', 'Adding ox_target interaction to NPC')
        exports.ox_target:addLocalEntity(npc, {
            {
                    name = 'cs_casino_npc_' .. i,
                icon = 'fas fa-dice',
                    label = GetResolvedLabel('openLabel'),
                distance = 2.0,
                                    onSelect = function()
                        openCasinoWithChecks()
                    end
            }
        })
            debugPrint('npcs', 'ox_target interaction added successfully')
        end
        
        debugPrint('npcs', 'Successfully created casino NPC #' .. i .. ' at: ' .. tostring(npcData.coords))
        print('^2[CS Casino] ^7Successfully spawned NPC #' .. i .. ' (' .. npcData.model .. ')')
        
        ::continue::
    end
    
    debugPrint('npcs', 'NPC creation process completed. Total NPCs spawned: ' .. #spawnedNPCs)
    print('^2[CS Casino] ^7NPC spawning completed. Total NPCs: ' .. #spawnedNPCs)
end

-- Clean up spawned NPCs
local function CleanupNPCs()
    debugPrint('npcs', 'Cleaning up spawned NPCs...')
    for i, npc in pairs(spawnedNPCs) do
        if DoesEntityExist(npc) then
            DeleteEntity(npc)
            debugPrint('npcs', 'Deleted NPC #' .. i)
        end
    end
    spawnedNPCs = {}
    debugPrint('npcs', 'NPC cleanup completed')
end

-- Resource start/stop events
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        debugPrint('events', 'CS Casino client starting...')
        
        -- Initialize systems that don't require active player immediately
        CreateCasinoBlips()
        SetupCasinoInteractions()
        
        -- Wait for player to spawn before starting interaction systems
        CreateThread(function()
            while not NetworkIsPlayerActive(PlayerId()) do
                Wait(100)
            end
            
            debugPrint('events', 'Player is now active, starting interaction systems...')
            
            -- Start distance checking and key handling now that player is active
            CheckCasinoDistance()
            HandleKeyPress()
            
            debugPrint('events', 'Waiting additional 3 seconds for world to load...')
            Wait(3000) -- Additional wait for world to fully load
            
        CreateCasinoNPCs()
        end)
        
        debugPrint('events', 'Client started successfully')
        print('^2[CS Casino] ^7Client started - NPCs will spawn when player is ready')
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        debugPrint('events', 'CS Casino client stopping...')
        
        if isUIOpen then
            SetNuiFocus(false, false)
            isUIOpen = false
        end
        
        -- Clean up blips
        for _, blip in pairs(blips) do
            if DoesBlipExist(blip) then
                RemoveBlip(blip)
            end
        end
        
        -- Clean up NPCs
        CleanupNPCs()
        
        -- Hide TextUI if shown
        if nearCasino and (Config.InteractionType == 'ox_lib' or Config.InteractionType == 'both') then
            exports.ox_lib:hideTextUI()
        end
        
        debugPrint('events', 'Client stopped successfully')
    end
end)

-- Utility functions

-- Cooldown tracking variables
local isOnCooldown = false
local cooldownEndTime = 0

-- Function to check if player can open cases (cooldown check)
local lastCaseOpenAttempt = 0
function canOpenCase()
    local currentTime = GetGameTimer()
    local timeSinceLastAttempt = currentTime - lastCaseOpenAttempt
    local cooldownTime = 6000 -- 6 seconds between case opens (60000ms / 10 limit)
    
    if timeSinceLastAttempt < cooldownTime then
        local remainingTime = math.ceil((cooldownTime - timeSinceLastAttempt) / 1000)
        return false, remainingTime
    end
    
    return true, 0
end

-- Enhanced casino opening with cooldown prevention
function openCasinoWithChecks()
    -- Check if currently on cooldown
    if isCurrentlyOnCooldown() then
        local currentTime = GetGameTimer()
        local remainingMs = (cooldownEndTime or 0) - currentTime
        local remainingSeconds = math.ceil(remainingMs / 1000)
        
        -- Ensure positive seconds
        if remainingSeconds <= 0 then
            remainingSeconds = 1
        end
        
        local cooldownMessage = Config.Titles.notifications.cooldownActive:gsub('{time}', remainingSeconds == 1 and (remainingSeconds .. ' second') or (remainingSeconds .. ' seconds'))
        exports.ox_lib:notify({
            type = 'error',
            description = cooldownMessage,
            duration = 3000
        })
        return
    end
    
    -- Open casino normally
    TriggerServerEvent('cs-casino:server:openCasino')
end

-- Function to check if player is near casino NPC
function IsNearCasinoNPC()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    
    for _, npcData in pairs(Config.NPCLocations) do
        local distance = #(playerCoords - vector3(npcData.coords.x, npcData.coords.y, npcData.coords.z))
        if distance < 3.0 then
            return true
        end
    end
    
    return false
end

-- Handle rate limit responses
RegisterNetEvent('cs-casino:client:rateLimited', function(data)
    debugPrint('events', 'Received rate limit response: ' .. data.eventType)
    
    if data.eventType == 'openCase' then
        -- Set cooldown state
        isOnCooldown = true
        cooldownEndTime = GetGameTimer() + (data.remainingTime * 1000)
        
        -- Reset client-side case opening state
        currentCaseOpening = false
        
        -- Reset case opening UI immediately with proper message type
        SendNUIMessage({
            type = 'resetCaseOpening',
            error = data.error or 'Rate limited'
        })
        
        -- Start cooldown notification system
        startCooldownNotifications(data.remainingTime)
        
    elseif data.eventType == 'openCasino' then
        -- Set cooldown state to prevent casino opening
        isOnCooldown = true
        cooldownEndTime = GetGameTimer() + (data.remainingTime * 1000)
        
        -- Start cooldown notification system
        startCooldownNotifications(data.remainingTime)
    end
end)

-- Function to start continuous cooldown notifications
function startCooldownNotifications(initialTime)
    CreateThread(function()
        while isOnCooldown and cooldownEndTime do
            local currentTime = GetGameTimer()
            local remainingMs = cooldownEndTime - currentTime
            local remainingSeconds = math.ceil(remainingMs / 1000)
            
            if remainingMs <= 0 then
                -- Cooldown expired
                isOnCooldown = false
                cooldownEndTime = 0
                
                -- Send UI reset message to ensure case opening modal is closed
                SendNUIMessage({
                    type = 'resetCaseOpening',
                    error = 'Cooldown expired - resetting UI'
                })
                
                exports.ox_lib:notify({
                    type = 'success',
                    description = 'Cooldown expired! You can now open cases again.',
                    duration = 3000
                })
                break
            else
                -- Show remaining time
                local cooldownMessage = Config.Titles.notifications.cooldownActive:gsub('{time}', remainingSeconds == 1 and (remainingSeconds .. ' second') or (remainingSeconds .. ' seconds'))
                exports.ox_lib:notify({
                    type = 'error',
                    description = cooldownMessage,
                    duration = 2000
                })
                Wait(3000) -- Show notification every 3 seconds
            end
        end
    end)
end

-- Function to check if currently on cooldown
function isCurrentlyOnCooldown()
    if isOnCooldown and cooldownEndTime then
        local currentTime = GetGameTimer()
        if currentTime >= cooldownEndTime then
            isOnCooldown = false
            cooldownEndTime = 0
            return false
        end
        return true
    end
    return false
end



-- Export functions for other resources
exports('openCasino', function()
    openCasinoWithChecks()
end)

exports('isUIOpen', function()
    return isUIOpen
end)

-- Ensure NPCs spawn for players who join after server startup
AddEventHandler('playerSpawned', function()
    debugPrint('events', 'Player spawned, checking if systems need to be started...')
    
    -- Wait a bit for the player to fully load
    SetTimeout(2000, function()
        -- Start interaction systems if not already started
        debugPrint('events', 'Starting interaction systems from playerSpawned...')
        CheckCasinoDistance()
        HandleKeyPress()
        
        -- Check if NPCs already exist
        if #spawnedNPCs == 0 then
            debugPrint('events', 'No NPCs found, creating them now...')
            CreateCasinoNPCs()
        else
            debugPrint('events', 'NPCs already exist (' .. #spawnedNPCs .. ' found), skipping creation')
        end
    end)
end)

-- Admin command to manually spawn NPCs (for testing)
RegisterCommand('casino:spawnnpcs', function()
    CleanupNPCs()
    Wait(1000)
    CreateCasinoNPCs()
    print('^2[CS Casino] ^7Manual NPC spawn triggered')
end, false)

-- Admin command to cleanup NPCs (for testing)
RegisterCommand('casino:cleannpcs', function()
    CleanupNPCs()
    print('^2[CS Casino] ^7NPCs cleaned up')
end, false)

-- Command to manually reset UI if it gets stuck
RegisterCommand('casino:resetui', function()
    -- Reset client-side state
    currentCaseOpening = false
    isOnCooldown = false
    cooldownEndTime = 0
    
    SendNUIMessage({
        type = 'resetCaseOpening',
        error = 'Manual reset'
    })
    
    print('^2[CS Casino] ^7UI and cooldown state reset')
end, false)
