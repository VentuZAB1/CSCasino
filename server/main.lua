-- CS Casino Server Main File
-- QBox Framework Integration

-- Debug helper function
local function debugPrint(category, message)
    if not Config.Debug.enabled then return end
    if not Config.Debug.server[category] then return end
    
    local timestamp = os.date('%H:%M:%S')
    print(string.format('^2[%s] [CS Casino Debug/%s] ^7%s', timestamp, category, message))
end

-- Security System
local playerEventCounts = {}
local playerCooldowns = {}

-- Clean up player data on disconnect
AddEventHandler('playerDropped', function()
    local src = source
    playerEventCounts[src] = nil
    playerCooldowns[src] = nil
end)

-- Security validation functions
local function validatePlayer(src)
    local Player = exports.qbx_core:GetPlayer(src)
    if not Player then
        if Config.Security.logging.enabled then
            print('^1[CS Casino Security] ^7Invalid player attempted action: ' .. src)
        end
        return false
    end
    return Player
end

local function getPlayerDataForWebhook(src, Player)
    Player = Player or exports.qbx_core:GetPlayer(src)
    if not Player then
        return { source = src, name = 'Unknown', license = 'Unknown' }
    end
    
    return {
        name = Player.PlayerData.name or 'Unknown',
        source = src,
        license = Player.PlayerData.license or 'Unknown',
        citizenid = Player.PlayerData.citizenid or 'Unknown'
    }
end

local function checkRateLimit(src, eventName)
    if not Config.Security.enableRateLimiting then return true end
    
    local currentTime = os.time()
    
    -- Initialize player tracking
    if not playerEventCounts[src] then
        playerEventCounts[src] = {}
    end
    
    if not playerEventCounts[src][eventName] then
        playerEventCounts[src][eventName] = {
            count = 0,
            firstAttempt = currentTime,
            lastMinute = currentTime
        }
    end
    
    local eventData = playerEventCounts[src][eventName]
    
    -- Reset counter if a minute has passed
    if currentTime - eventData.lastMinute >= 60 then
        eventData.count = 0
        eventData.firstAttempt = currentTime
        eventData.lastMinute = currentTime
    end
    
    -- Check specific event limits
    local limit = Config.Security.eventLimits[eventName] or Config.Security.maxEventsPerMinute
    
    if eventData.count >= limit then
        if Config.Security.logging.enabled then
            print('^1[CS Casino Security] ^7Rate limit exceeded for player ' .. src .. ' on event: ' .. eventName)
        end
        
        -- Calculate remaining cooldown time with safety check
        local firstAttempt = eventData.firstAttempt or eventData.lastMinute or currentTime
        
        -- Debug log if firstAttempt was nil
        if not eventData.firstAttempt then
            debugPrint('security', 'Warning: firstAttempt was nil for player ' .. src .. ' event ' .. eventName)
        end
        
        local timeRemaining = math.ceil(60 - (currentTime - firstAttempt))
        
        -- Ensure time remaining is positive
        if timeRemaining <= 0 then
            timeRemaining = 1
        end
        
        local timeText = timeRemaining == 1 and (timeRemaining .. ' second') or (timeRemaining .. ' seconds')
        local cooldownMessage = Config.Titles.notifications.cooldownActive:gsub('{time}', timeText)
        
        -- Send cooldown notification to player
        TriggerClientEvent('ox_lib:notify', src, {
            type = 'error',
            description = cooldownMessage,
            duration = 3000
        })
        
        -- Check for ban threshold
        if Config.Security.banOnExcessiveSpam and eventData.count >= Config.Security.spamThreshold then
            local Player = exports.qbx_core:GetPlayer(src)
            local playerData = getPlayerDataForWebhook(src, Player)
            
            -- Log ban with webhook
            securityLog('Player banned for excessive spam (' .. eventData.count .. ' events in 1 minute)', 'ban', playerData)
            
            DropPlayer(src, Config.Titles.security.banMessage)
        end
        
        return false
    end
    
    eventData.count = eventData.count + 1
    return true
end

local function validateInput(data, expectedType, maxLength)
    if not data then return false end
    
    if expectedType == 'string' then
        if type(data) ~= 'string' then return false end
        if Config.Security.validation.maxStringLength and #data > (maxLength or Config.Security.validation.maxStringLength) then
            return false
        end
    elseif expectedType == 'number' then
        if type(data) ~= 'number' or data < 0 or data > 999999 then return false end
    elseif expectedType == 'table' then
        if type(data) ~= 'table' then return false end
    end
    
    return true
end

local function validateCaseType(caseType)
    if not Config.Security.validation.allowedCaseTypes then return true end
    return Config.Cases[caseType] ~= nil
end

local function validatePlayerPosition(src)
    if not Config.Security.validation.checkPlayerPosition then return true end
    
    local playerPed = GetPlayerPed(src)
    if not playerPed or playerPed == 0 then return false end
    
    local playerCoords = GetEntityCoords(playerPed)
    
    -- Check distance to casino locations
    for _, location in pairs(Config.CasinoLocations) do
        local distance = #(playerCoords - location.coords)
        if distance <= Config.Security.validation.maxDistance then
            debugPrint('security', 'Player validated at casino location')
            return true
        end
    end
    
    -- Check distance to NPCs
    for _, npcData in pairs(Config.NPCLocations) do
        local npcCoords = vector3(npcData.coords.x, npcData.coords.y, npcData.coords.z)
        local distance = #(playerCoords - npcCoords)
        if distance <= Config.Security.validation.maxDistance then
            debugPrint('security', 'Player validated at NPC location')
            return true
        end
    end
    
    debugPrint('security', 'Player position validation failed - too far from casino/NPCs')
    return false
end

local function sendDiscordWebhook(message, level, playerData)
    local webhookUrl = Config.Security.logging.webhookUrl
    if not webhookUrl or webhookUrl == '' then return end
    
    -- Color based on alert level
    local color = 16711680 -- Red for error
    if level == 'warning' then
        color = 16776960 -- Yellow for warning
    elseif level == 'info' then
        color = 65280 -- Green for info
    elseif level == 'ban' then
        color = 9961472 -- Dark red for bans
    end
    
    -- Get server info
    local serverName = GetConvar('sv_hostname', 'FiveM Server')
    local timestamp = os.date('%Y-%m-%dT%H:%M:%S')
    
    -- Build player info if available
    local playerInfo = ''
    if playerData then
        playerInfo = string.format('\n**Player:** %s\n**ID:** %s\n**License:** %s', 
            playerData.name or 'Unknown',
            playerData.source or 'Unknown',
            playerData.license or 'Unknown'
        )
    end
    
    local embed = {
        {
            title = Config.Titles.security.alertTitle,
            description = message .. playerInfo,
            color = color,
            timestamp = timestamp .. 'Z',
            footer = {
                text = serverName,
                icon_url = 'https://cdn.discordapp.com/attachments/1234567890/1234567890/fivem_logo.png'
            },
            fields = {
                {
                    name = '🛡️ Alert Level',
                    value = level:upper(),
                    inline = true
                },
                {
                    name = '⏰ Time',
                    value = os.date('%H:%M:%S'),
                    inline = true
                },
                {
                    name = '📊 Server',
                    value = GetConvar('sv_projectName', Config.Titles.casinoName .. ' Server'),
                    inline = true
                }
            }
        }
    }
    
    local payload = {
        username = Config.Titles.security.webhookUsername,
        avatar_url = 'https://cdn.discordapp.com/attachments/1234567890/1234567890/security_bot.png',
        embeds = embed
    }
    
    -- Send webhook
    PerformHttpRequest(webhookUrl, function(statusCode, response, headers)
        if statusCode ~= 204 then
            print('^1[CS Casino Security] ^7Failed to send Discord webhook. Status: ' .. statusCode)
        end
    end, 'POST', json.encode(payload), {
        ['Content-Type'] = 'application/json'
    })
end

local function securityLog(message, level, playerData)
    if not Config.Security.logging.enabled then return end
    
    local timestamp = os.date('%Y-%m-%d %H:%M:%S')
    local logMessage = string.format('[%s] %s %s', timestamp, Config.Titles.security.logPrefix, message)
    
    if level == 'error' then
        print('^1' .. logMessage .. '^7')
    elseif level == 'warning' then
        print('^3' .. logMessage .. '^7')
    else
        print('^2' .. logMessage .. '^7')
    end
    
    -- Send to Discord webhook if configured and enabled
    if Config.Security.logging.webhookEnabled and 
       Config.Security.logging.webhookUrl and 
       Config.Security.logging.webhookUrl ~= '' then
        
        local shouldSend = false
        if level == 'error' and Config.Security.logging.webhookOnErrors then
            shouldSend = true
        elseif level == 'warning' and Config.Security.logging.webhookOnWarnings then
            shouldSend = true
        elseif level == 'ban' and Config.Security.logging.webhookOnBans then
            shouldSend = true
        end
        
        if shouldSend then
            sendDiscordWebhook(message, level, playerData)
        end
    end
end

-- Helper function to get random weighted item from case
local function GetRandomItemFromCase(caseType)
    local caseData = Config.Cases[caseType]
    if not caseData then return nil end
    
    local totalWeight = 0
    for _, item in pairs(caseData.items) do
        totalWeight = totalWeight + item.weight
    end
    
    local randomWeight = math.random(1, totalWeight)
    local currentWeight = 0
    
    for _, item in pairs(caseData.items) do
        currentWeight = currentWeight + item.weight
        if randomWeight <= currentWeight then
            local amount = math.random(item.min, item.max)
            return {
                item = item.item,
                amount = amount
            }
        end
    end
    
    return nil
end

-- Helper function to get item value for selling
local function GetItemSellValue(itemName, amount)
    -- Calculate base value from all cases to determine sell price
    local totalValue = 0
    local totalAppearances = 0
    
    for caseType, caseData in pairs(Config.Cases) do
        for _, item in pairs(caseData.items) do
            if item.item == itemName then
                -- Weight-based value calculation
                local itemValue = (caseData.price * item.weight) / 100
                totalValue = totalValue + itemValue
                totalAppearances = totalAppearances + 1
            end
        end
    end
    
    if totalAppearances == 0 then return 0 end
    
    local baseValue = (totalValue / totalAppearances) * amount
    local sellValue = math.floor(baseValue * (1 + Config.SellMargin))
    
    return sellValue, math.floor(baseValue)
end

-- Level System Functions
local function CalculateRequiredXP(level)
    if level <= 1 then return 0 end
    
    local required = Config.LevelSystem.xpRequiredBase
    for i = 2, level do
        if i > 2 then
            required = math.floor(required * Config.LevelSystem.xpMultiplier)
        end
    end
    return required
end

local function CalculateLevelFromXP(totalXP)
    -- Handle nil or invalid XP values
    if not totalXP or type(totalXP) ~= 'number' then
        totalXP = 0
    end
    
    local level = 1
    local currentLevelXP = 0
    
    while true do
        local nextLevelXP = CalculateRequiredXP(level + 1)
        if totalXP < nextLevelXP then
            break
        end
        level = level + 1
        currentLevelXP = nextLevelXP
    end
    
    return level, currentLevelXP, CalculateRequiredXP(level + 1)
end

local function UpdatePlayerExperience(citizenid, xpToAdd)
    -- Get current player data
    local currentData = GetPlayerData(citizenid)
    
    -- Handle missing or invalid data
    if not currentData then
        debugPrint('levelSystem', 'No player data found for XP update: ' .. tostring(citizenid))
        return nil
    end
    
    local oldLevel = currentData.level or 1
    local oldXP = currentData.experience or 0
    local newTotalXP = oldXP + (xpToAdd or 0)
    
    -- Ensure non-negative XP
    if newTotalXP < 0 then
        newTotalXP = 0
    end
    
    -- Calculate new level
    local newLevel, currentLevelXP, nextLevelXP = CalculateLevelFromXP(newTotalXP)
    
    -- Update database
    MySQL.Async.execute('UPDATE cs_casino_players SET experience = ?, level = ? WHERE citizenid = ?', {
        newTotalXP, newLevel, citizenid
    })
    
    debugPrint('levelSystem', string.format('Player %s: %d XP (+%d) -> Level %d (was %d)', 
        citizenid, newTotalXP, xpToAdd or 0, newLevel, oldLevel))
    
    return {
        oldLevel = oldLevel,
        newLevel = newLevel,
        oldXP = oldXP,
        newXP = newTotalXP,
        currentLevelXP = currentLevelXP,
        nextLevelXP = nextLevelXP,
        xpToNext = nextLevelXP - newTotalXP
    }
end

local function RecalculatePlayerLevel(citizenid)
    -- Get current player data
    local currentData = GetPlayerData(citizenid)
    
    -- Handle cases where player data might be missing or invalid
    if not currentData then
        debugPrint('levelSystem', 'No player data found for citizenid: ' .. tostring(citizenid))
        return { wasFixed = false, error = 'No player data' }
    end
    
    local totalXP = currentData.experience or 0
    local currentLevel = currentData.level or 1
    
    -- Calculate correct level from total XP
    local correctLevel, currentLevelXP, nextLevelXP = CalculateLevelFromXP(totalXP)
    
    -- Update if level is different
    if correctLevel ~= currentLevel then
        MySQL.Async.execute('UPDATE cs_casino_players SET level = ?, experience = ? WHERE citizenid = ?', {
            correctLevel, totalXP, citizenid
        })
        
        debugPrint('levelSystem', string.format('Fixed player %s level: %d -> %d (XP: %d)', 
            citizenid, currentLevel, correctLevel, totalXP))
            
        return {
            oldLevel = currentLevel,
            newLevel = correctLevel,
            wasFixed = true
        }
    end
    
    return { wasFixed = false }
end

-- Event: Open Casino UI
RegisterNetEvent('cs-casino:server:openCasino', function()
    local src = source
    
    -- Security checks
    if not checkRateLimit(src, 'cs-casino:server:openCasino') then
        securityLog('Player ' .. src .. ' rate limited on openCasino', 'warning')
        
        -- Calculate and send cooldown notification for casino opening
        local currentTime = os.time()
        local eventData = playerEventCounts[src] and playerEventCounts[src]['cs-casino:server:openCasino']
        local timeRemaining = 1
        
        if eventData and eventData.firstAttempt then
            timeRemaining = math.ceil(60 - (currentTime - eventData.firstAttempt))
            if timeRemaining <= 0 then timeRemaining = 1 end
        end
        
        local cooldownMessage = Config.Titles.notifications.cooldownActive:gsub('{time}', timeRemaining == 1 and (timeRemaining .. ' second') or (timeRemaining .. ' seconds'))
        TriggerClientEvent('ox_lib:notify', src, {
            type = 'error',
            description = cooldownMessage,
            duration = 3000
        })
        
        -- Send rate limit response to prevent UI opening
        TriggerClientEvent('cs-casino:client:rateLimited', src, {
            eventType = 'openCasino',
            error = 'Rate limit exceeded',
            remainingTime = timeRemaining
        })
        return
    end
    
    local Player = validatePlayer(src)
    if not Player then return end
    
    if not validatePlayerPosition(src) then
        securityLog('Player ' .. src .. ' attempted to open casino from invalid position', 'warning')
        TriggerClientEvent('ox_lib:notify', src, {
            type = 'error',
            description = Config.Titles.notifications.mustBeNearCasino
        })
        return
    end
    
    -- Fix player level if needed (recalculate from XP)
    local levelFix = RecalculatePlayerLevel(Player.PlayerData.citizenid)
    if levelFix.wasFixed then
        TriggerClientEvent('ox_lib:notify', src, {
            type = 'success',
            description = 'Level corrected! You are now level ' .. levelFix.newLevel,
            duration = 5000
        })
    elseif levelFix.error then
        debugPrint('levelSystem', 'Error fixing level for player ' .. src .. ': ' .. levelFix.error)
    end
    
    local playerData = GetPlayerData(Player.PlayerData.citizenid)
    local playerMoney = exports.qbx_core:GetMoney(src, Config.Currency)
    
    TriggerClientEvent('cs-casino:client:openUI', src, {
        playerData = playerData,
        playerMoney = playerMoney,
        cases = Config.Cases,
        inventoryImages = Config.InventoryImages,
        inventoryConfig = Config.InventoryImages, -- Add inventory config for image paths
        branding = Config.Branding,
        titles = Config.Titles,
        debug = Config.Debug
    })
    
    if Config.Security.logging.logValidActions then
        securityLog('Player ' .. Player.PlayerData.name .. ' (' .. src .. ') opened casino UI', 'info')
    end
end)

-- Event: Purchase and open case
RegisterNetEvent('cs-casino:server:openCase', function(caseType)
    local src = source
    
    -- Security checks
    if not checkRateLimit(src, 'cs-casino:server:openCase') then
        local Player = exports.qbx_core:GetPlayer(src)
        local playerData = Player and {
            name = Player.PlayerData.name,
            source = src,
            license = Player.PlayerData.license
        } or { source = src }
        securityLog('Rate limit exceeded on openCase', 'warning', playerData)
        
        -- Calculate and send cooldown notification
        local currentTime = os.time()
        local eventData = playerEventCounts[src] and playerEventCounts[src]['cs-casino:server:openCase']
        local timeRemaining = 1
        
        if eventData and eventData.firstAttempt then
            timeRemaining = math.ceil(60 - (currentTime - eventData.firstAttempt))
            if timeRemaining <= 0 then timeRemaining = 1 end
        end
        
        local cooldownMessage = Config.Titles.notifications.cooldownActive:gsub('{time}', timeRemaining == 1 and (timeRemaining .. ' second') or (timeRemaining .. ' seconds'))
        TriggerClientEvent('ox_lib:notify', src, {
            type = 'error',
            description = cooldownMessage,
            duration = 3000
        })
        
        -- Send rate limit response to client to reset UI
        TriggerClientEvent('cs-casino:client:rateLimited', src, {
            eventType = 'openCase',
            error = 'Rate limit exceeded',
            remainingTime = timeRemaining
        })
        return
    end
    
    local Player = validatePlayer(src)
    if not Player then return end
    
    -- Input validation
    if not validateInput(caseType, 'string', 50) then
        local playerData = {
            name = Player.PlayerData.name,
            source = src,
            license = Player.PlayerData.license
        }
        securityLog('Invalid caseType sent: ' .. tostring(caseType), 'error', playerData)
        return
    end
    
    if not validateCaseType(caseType) then
        local playerData = {
            name = Player.PlayerData.name,
            source = src,
            license = Player.PlayerData.license
        }
        securityLog('Attempted to open invalid case type: ' .. caseType, 'error', playerData)
        TriggerClientEvent('ox_lib:notify', src, {
            type = 'error',
            description = Config.Titles.notifications.invalidCase
        })
        return
    end
    
    local caseData = Config.Cases[caseType]
    
    local playerData = GetPlayerData(Player.PlayerData.citizenid)
    
    -- Check level requirement
    if playerData.level < caseData.requiredLevel then
        TriggerClientEvent('ox_lib:notify', src, {
            type = 'error',
            description = Config.Titles.notifications.levelRequired:gsub('{level}', caseData.requiredLevel)
        })
        return
    end
    
    -- Check if player has enough money
    local playerMoney = exports.qbx_core:GetMoney(src, Config.Currency)
    if playerMoney < caseData.price then
        TriggerClientEvent('ox_lib:notify', src, {
            type = 'error',
            description = Config.Titles.notifications.insufficientFunds
        })
        return
    end
    
    -- Remove money
    if not exports.qbx_core:RemoveMoney(src, Config.Currency, caseData.price, 'cs-casino-case-purchase') then
        TriggerClientEvent('ox_lib:notify', src, {
            type = 'error',
            description = Config.Titles.notifications.errorOccurred
        })
        return
    end
    
    -- Get random item
    local wonItem = GetRandomItemFromCase(caseType)
    if not wonItem then
        TriggerClientEvent('ox_lib:notify', src, {
            type = 'error',
            description = Config.Titles.notifications.errorOccurred
        })
        -- Refund money
        exports.qbx_core:AddMoney(src, Config.Currency, caseData.price)
        return
    end
    
    -- Don't give item immediately - wait for player choice (Keep/Sell)
    
    -- Update player stats and experience
    UpdatePlayerStats(Player.PlayerData.citizenid, caseData.price)
    local levelData = UpdatePlayerExperience(Player.PlayerData.citizenid, Config.LevelSystem.xpPerCase)
    
    -- Add to history
    AddCaseHistory(Player.PlayerData.citizenid, caseType, wonItem.item, wonItem.amount, caseData.price)
    
    -- Get item label and sell value for display
    local itemData = exports.ox_inventory:Items(wonItem.item)
    local itemLabel = itemData and itemData.label or wonItem.item
    local sellValue = GetItemSellValue(wonItem.item, wonItem.amount)
    
    -- Send result to client (item not given yet)
    TriggerClientEvent('cs-casino:client:caseOpened', src, {
        success = true,
        item = wonItem.item,
        amount = wonItem.amount,
        itemLabel = itemLabel,
        sellValue = sellValue,
        caseType = caseType,
        levelData = levelData,
        newPlayerData = GetPlayerData(Player.PlayerData.citizenid)
    })
    
    -- Level up notification
    if levelData and levelData.newLevel and levelData.oldLevel and levelData.newLevel > levelData.oldLevel then
        TriggerClientEvent('ox_lib:notify', src, {
            type = 'success',
            description = 'Level Up! You are now level ' .. levelData.newLevel,
            duration = 5000
        })
    end
    
    debugPrint('playerActions', Player.PlayerData.name .. ' opened ' .. caseType .. ' and won ' .. wonItem.amount .. 'x ' .. wonItem.item .. ' (pending choice)')
end)

-- Event: Finalize case opening (Keep or Sell)
RegisterNetEvent('cs-casino:server:finalizeCase', function(data)
    local src = source
    local Player = exports.qbx_core:GetPlayer(src)
    
    if not Player then return end
    
    local action = data.action -- 'keep' or 'sell'
    local item = data.item
    local amount = data.amount
    
    if action == 'keep' then
        -- Give item to player
        local success = exports.ox_inventory:AddItem(src, item, amount)
        if success then
            TriggerClientEvent('ox_lib:notify', src, {
                type = 'success',
                description = Config.Titles.notifications.itemKept
            })
            
            debugPrint('playerActions', Player.PlayerData.name .. ' kept ' .. amount .. 'x ' .. item)
        else
            TriggerClientEvent('ox_lib:notify', src, {
                type = 'error',
                description = Config.Titles.notifications.errorOccurred
            })
        end
        
    elseif action == 'sell' then
        -- Give money with +3% margin
        local sellValue = data.sellValue
        exports.qbx_core:AddMoney(src, Config.Currency, sellValue, 'cs-casino-item-sell')
        
        -- Add to sell history
        AddSellHistory(Player.PlayerData.citizenid, item, amount, sellValue)
        
        TriggerClientEvent('ox_lib:notify', src, {
            type = 'success',
            description = Config.Titles.notifications.itemSold:gsub('{amount}', sellValue)
        })
        
        debugPrint('playerActions', Player.PlayerData.name .. ' sold ' .. amount .. 'x ' .. item .. ' for $' .. sellValue)
    end
end)

-- Event: Collect item from case (add to pending items)
RegisterNetEvent('cs-casino:server:collectItem', function(data)
    local src = source
    
    -- Security checks
    if not checkRateLimit(src, 'cs-casino:server:collectItem') then
        securityLog('Player ' .. src .. ' rate limited on collectItem', 'warning')
        return
    end
    
    local Player = validatePlayer(src)
    if not Player then return end
    
    -- Input validation
    if not validateInput(data, 'table') then
        securityLog('Player ' .. src .. ' sent invalid collectItem data', 'error')
        return
    end
    
    if not validateInput(data.item, 'string', 50) or 
       not validateInput(data.amount, 'number') or 
       not validateInput(data.sellValue, 'number') or
       not validateInput(data.itemLabel, 'string', 100) or
       not validateInput(data.caseType, 'string', 50) then
        securityLog('Player ' .. src .. ' sent invalid collectItem parameters', 'error')
        return
    end
    
    -- Validate case type exists
    if not validateCaseType(data.caseType) then
        securityLog('Player ' .. src .. ' attempted to collect item with invalid case type: ' .. tostring(data.caseType), 'error')
        return
    end
    
    -- Generate unique ID for the pending item
    local itemId = src .. '_' .. os.time() .. '_' .. math.random(1000, 9999)
    
    -- Store item in database
    AddPendingItem(Player.PlayerData.citizenid, itemId, data.item, data.amount, data.sellValue, data.itemLabel, data.caseType)
    
    TriggerClientEvent('ox_lib:notify', src, {
        type = 'success',
        description = Config.Titles.notifications.caseOpened
    })
    
    debugPrint('playerActions', Player.PlayerData.name .. ' collected ' .. data.amount .. 'x ' .. data.item .. ' (pending in database)')
end)

-- Event: Get pending items
RegisterNetEvent('cs-casino:server:getPendingItems', function()
    local src = source
    
    -- Security checks
    if not checkRateLimit(src, 'cs-casino:server:getPendingItems') then
        return
    end
    
    local Player = validatePlayer(src)
    if not Player then return end
    
    -- Get items from database
    local pendingItems = GetPendingItems(Player.PlayerData.citizenid)
    local items = {}
    
    for _, item in pairs(pendingItems) do
        table.insert(items, {
            id = item.id,
            name = item.item_name,
            amount = item.item_amount,
            sellValue = item.sell_value,
            label = item.item_label,
            caseType = item.case_type
        })
    end
    
    TriggerClientEvent('cs-casino:client:pendingItems', src, { items = items })
end)

-- Event: Keep pending item (add to inventory)
RegisterNetEvent('cs-casino:server:keepPendingItem', function(data)
    local src = source
    
    -- Security checks
    if not checkRateLimit(src, 'cs-casino:server:keepPendingItem') then
        securityLog('Player ' .. src .. ' rate limited on keepPendingItem', 'warning')
        return
    end
    
    local Player = validatePlayer(src)
    if not Player then return end
    
    -- Input validation
    if not validateInput(data, 'table') or not validateInput(data.itemId, 'string', 100) then
        securityLog('Player ' .. src .. ' sent invalid keepPendingItem data', 'error')
        return
    end
    
    local itemId = data.itemId
    
    -- Get item from database
    local pendingItems = GetPendingItems(Player.PlayerData.citizenid)
    local item = nil
    
    for _, pendingItem in pairs(pendingItems) do
        if pendingItem.id == itemId then
            item = pendingItem
            break
        end
    end
    
    if not item then return end
    
    -- Add item to inventory
    local success = exports.ox_inventory:AddItem(src, item.item_name, item.item_amount)
    if success then
        -- Remove from pending items database
        RemovePendingItem(itemId)
        
        TriggerClientEvent('ox_lib:notify', src, {
            type = 'success',
            description = Config.Titles.notifications.itemKept
        })
        
        -- Refresh pending items list
        local updatedItems = GetPendingItems(Player.PlayerData.citizenid)
        local items = {}
        for _, pendingItem in pairs(updatedItems) do
            table.insert(items, {
                id = pendingItem.id,
                name = pendingItem.item_name,
                amount = pendingItem.item_amount,
                sellValue = pendingItem.sell_value,
                label = pendingItem.item_label,
                caseType = pendingItem.case_type
            })
        end
        TriggerClientEvent('cs-casino:client:pendingItems', src, { items = items })
        
        debugPrint('playerActions', Player.PlayerData.name .. ' kept ' .. item.item_amount .. 'x ' .. item.item_name)
    else
        TriggerClientEvent('ox_lib:notify', src, {
            type = 'error',
            description = Config.Titles.notifications.errorOccurred
        })
    end
end)

-- Event: Sell pending item
RegisterNetEvent('cs-casino:server:sellPendingItem', function(data)
    local src = source
    
    -- Security checks
    if not checkRateLimit(src, 'cs-casino:server:sellPendingItem') then
        securityLog('Player ' .. src .. ' rate limited on sellPendingItem', 'warning')
        return
    end
    
    local Player = validatePlayer(src)
    if not Player then return end
    
    -- Input validation
    if not validateInput(data, 'table') or not validateInput(data.itemId, 'string', 100) then
        securityLog('Player ' .. src .. ' sent invalid sellPendingItem data', 'error')
        return
    end
    
    local itemId = data.itemId
    
    -- Get item from database
    local pendingItems = GetPendingItems(Player.PlayerData.citizenid)
    local item = nil
    
    for _, pendingItem in pairs(pendingItems) do
        if pendingItem.id == itemId then
            item = pendingItem
            break
        end
    end
    
    if not item then return end
    
    -- Give money
    exports.qbx_core:AddMoney(src, Config.Currency, item.sell_value, 'cs-casino-item-sell')
    
    -- Add to sell history
    AddSellHistory(Player.PlayerData.citizenid, item.item_name, item.item_amount, item.sell_value, 0)
    
    -- Remove from pending items database
    RemovePendingItem(itemId)
    
    TriggerClientEvent('ox_lib:notify', src, {
        type = 'success',
        description = Config.Titles.notifications.itemSold:gsub('{amount}', item.sell_value)
    })
    
    -- Refresh pending items list
    local updatedItems = GetPendingItems(Player.PlayerData.citizenid)
    local items = {}
    for _, pendingItem in pairs(updatedItems) do
        table.insert(items, {
            id = pendingItem.id,
            name = pendingItem.item_name,
            amount = pendingItem.item_amount,
            sellValue = pendingItem.sell_value,
            label = pendingItem.item_label,
            caseType = pendingItem.case_type
        })
    end
    TriggerClientEvent('cs-casino:client:pendingItems', src, { items = items })
    
    debugPrint('playerActions', Player.PlayerData.name .. ' sold ' .. item.item_amount .. 'x ' .. item.item_name .. ' for $' .. item.sell_value)
end)

-- Event: Sell item back to casino
RegisterNetEvent('cs-casino:server:sellItem', function(itemName, amount)
    local src = source
    
    -- Security checks
    if not checkRateLimit(src, 'cs-casino:server:sellItem') then
        securityLog('Player ' .. src .. ' rate limited on sellItem', 'warning')
        return
    end
    
    local Player = validatePlayer(src)
    if not Player then return end
    
    -- Input validation
    if not validateInput(itemName, 'string', 50) or not validateInput(amount, 'number') then
        securityLog('Player ' .. src .. ' sent invalid sellItem parameters', 'error')
        return
    end
    
    -- Additional validation
    if amount <= 0 or amount > 1000 then
        securityLog('Player ' .. src .. ' attempted to sell invalid amount: ' .. amount, 'error')
        return
    end
    
    -- Check if player has the item
    local hasItem = exports.ox_inventory:RemoveItem(src, itemName, amount)
    if not hasItem then
        TriggerClientEvent('ox_lib:notify', src, {
            type = 'error',
            description = Config.Titles.notifications.errorOccurred
        })
        return
    end
    
    -- Calculate sell value
    local sellValue, originalValue = GetItemSellValue(itemName, amount)
    
    if sellValue <= 0 then
        TriggerClientEvent('ox_lib:notify', src, {
            type = 'error',
            description = Config.Titles.notifications.errorOccurred
        })
        -- Return item
        exports.ox_inventory:AddItem(src, itemName, amount)
        return
    end
    
    -- Add money to player
    exports.qbx_core:AddMoney(src, Config.Currency, sellValue, 'cs-casino-item-sell')
    
    -- Add to sell history
    AddSellHistory(Player.PlayerData.citizenid, itemName, amount, sellValue, originalValue)
    
    -- Get item label
    local itemData = exports.ox_inventory:Items(itemName)
    local itemLabel = itemData and itemData.label or itemName
    
    TriggerClientEvent('ox_lib:notify', src, {
        type = 'success',
        description = Config.Titles.notifications.itemSold:gsub('{amount}', sellValue)
    })
    
    -- Update client with new money amount
    TriggerClientEvent('cs-casino:client:updateMoney', src, exports.qbx_core:GetMoney(src, Config.Currency))
    
    debugPrint('playerActions', Player.PlayerData.name .. ' sold ' .. amount .. 'x ' .. itemName .. ' for $' .. sellValue)
end)

-- Event: Get player statistics
RegisterNetEvent('cs-casino:server:getStats', function()
    local src = source
    
    -- Security checks
    if not checkRateLimit(src, 'cs-casino:server:getStats') then
        return
    end
    
    local Player = validatePlayer(src)
    if not Player then return end
    
    local stats = GetPlayerStats(Player.PlayerData.citizenid)
    TriggerClientEvent('cs-casino:client:receiveStats', src, stats)
end)

-- Event: Get sellable items from inventory
RegisterNetEvent('cs-casino:server:getSellableItems', function()
    local src = source
    
    -- Security checks
    if not checkRateLimit(src, 'cs-casino:server:getSellableItems') then
        return
    end
    
    local Player = validatePlayer(src)
    if not Player then return end
    
    local playerItems = exports.ox_inventory:Search(src, 'count')
    local sellableItems = {}
    
    -- Check if playerItems is a valid table
    if not playerItems or type(playerItems) ~= 'table' then
        playerItems = {}
    end
    
    for _, playerItem in pairs(playerItems) do
        local sellValue, originalValue = GetItemSellValue(playerItem.name, playerItem.count)
        if sellValue > 0 then
            local itemData = exports.ox_inventory:Items(playerItem.name)
            table.insert(sellableItems, {
                name = playerItem.name,
                label = itemData and itemData.label or playerItem.name,
                count = playerItem.count,
                sellValue = sellValue,
                originalValue = originalValue,
                margin = Config.SellMargin * 100
            })
        end
    end
    
    TriggerClientEvent('cs-casino:client:receiveSellableItems', src, sellableItems)
end)

-- Admin command to fix all player levels
RegisterCommand('casino:fixlevels', function(source, args, rawCommand)
    local src = source
    
    -- Check if player is admin (console only for safety)
    if src ~= 0 then
        print('^1[CS Casino] ^7This command can only be run from console')
        return
    end
    
    print('^3[CS Casino] ^7Starting level fix process...')
    
    MySQL.Async.fetchAll('SELECT citizenid, experience, level FROM cs_casino_players', {}, function(players)
        if not players then
            print('^1[CS Casino] ^7Error: Could not fetch player data')
            return
        end
        
        local fixedCount = 0
        
        for _, player in pairs(players) do
            -- Handle nil XP values
            local xp = player.experience or 0
            local currentLevel = player.level or 1
            
            local correctLevel = CalculateLevelFromXP(xp)
            
            if correctLevel ~= currentLevel then
                MySQL.Async.execute('UPDATE cs_casino_players SET level = ?, experience = ? WHERE citizenid = ?', {
                    correctLevel, xp, player.citizenid
                })
                fixedCount = fixedCount + 1
                print(string.format('^2[CS Casino] ^7Fixed player %s: Level %d -> %d (XP: %d)', 
                    player.citizenid, currentLevel, correctLevel, xp))
            end
        end
        
        print(string.format('^2[CS Casino] ^7Level fix complete! Fixed %d out of %d players.', fixedCount, #players))
    end)
end, true) -- Restrict to admin

print('^2[CS Casino] ^7Server started successfully')
