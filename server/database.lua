-- Database Schema and Functions for CS Casino

local function CreateTables()
    -- Player levels and experience table
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `cs_casino_players` (
            `citizenid` varchar(50) NOT NULL,
            `level` int(11) DEFAULT 1,
            `experience` int(11) DEFAULT 0,
            `cases_opened` int(11) DEFAULT 0,
            `total_spent` int(11) DEFAULT 0,
            `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,
            `updated_at` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`citizenid`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]])

    -- Case opening history
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `cs_casino_history` (
            `id` int(11) NOT NULL AUTO_INCREMENT,
            `citizenid` varchar(50) NOT NULL,
            `case_type` varchar(50) NOT NULL,
            `item_won` varchar(50) NOT NULL,
            `item_amount` int(11) DEFAULT 1,
            `case_price` int(11) NOT NULL,
            `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            KEY `citizenid` (`citizenid`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]])

    -- Item sell transactions
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `cs_casino_sells` (
            `id` int(11) NOT NULL AUTO_INCREMENT,
            `citizenid` varchar(50) NOT NULL,
            `item_name` varchar(50) NOT NULL,
            `item_amount` int(11) NOT NULL,
            `sell_price` int(11) NOT NULL,
            `original_value` int(11) NOT NULL,
            `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            KEY `citizenid` (`citizenid`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]])

    -- Pending items table
    MySQL.query([[
        CREATE TABLE IF NOT EXISTS `cs_casino_pending_items` (
            `id` varchar(50) NOT NULL,
            `citizenid` varchar(50) NOT NULL,
            `item_name` varchar(50) NOT NULL,
            `item_amount` int(11) NOT NULL,
            `sell_value` int(11) NOT NULL,
            `item_label` varchar(100),
            `case_type` varchar(50) NOT NULL,
            `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            KEY `citizenid` (`citizenid`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
    ]])

    if Config.Debug then
        print('^2[CS Casino] ^7Database tables created successfully')
    end
end

-- Get or create player data
function GetPlayerData(citizenid)
    local result = MySQL.scalar.await('SELECT citizenid FROM cs_casino_players WHERE citizenid = ?', {citizenid})
    
    if not result then
        -- Create new player entry
        MySQL.insert('INSERT INTO cs_casino_players (citizenid, level, experience, cases_opened, total_spent) VALUES (?, ?, ?, ?, ?)', {
            citizenid, Config.DefaultLevel, 0, 0, 0
        })
        return {
            citizenid = citizenid,
            level = Config.DefaultLevel,
            experience = 0,
            cases_opened = 0,
            total_spent = 0
        }
    else
        -- Get existing player data
        local playerData = MySQL.single.await('SELECT * FROM cs_casino_players WHERE citizenid = ?', {citizenid})
        return playerData
    end
end

-- Update player experience and level
function UpdatePlayerExperience(citizenid, expGained)
    local playerData = GetPlayerData(citizenid)
    local newExp = playerData.experience + expGained
    local newLevel = playerData.level
    
    -- Calculate new level based on experience
    local expRequired = Config.LevelSystem.xpRequiredBase
    local currentLevelExp = 0
    
    for i = 1, Config.MaxLevel do
        local levelExpRequired = math.floor(expRequired * (Config.LevelSystem.xpMultiplier ^ (i - 1)))
        if newExp >= currentLevelExp + levelExpRequired then
            currentLevelExp = currentLevelExp + levelExpRequired
            newLevel = i + 1
        else
            break
        end
    end
    
    if newLevel > Config.MaxLevel then
        newLevel = Config.MaxLevel
    end
    
    -- Update database
    MySQL.update('UPDATE cs_casino_players SET level = ?, experience = ?, updated_at = NOW() WHERE citizenid = ?', {
        newLevel, newExp, citizenid
    })
    
    return {
        oldLevel = playerData.level,
        newLevel = newLevel,
        expGained = expGained,
        totalExp = newExp
    }
end

-- Update player stats when opening a case
function UpdatePlayerStats(citizenid, casePrice)
    local playerData = GetPlayerData(citizenid)
    MySQL.update('UPDATE cs_casino_players SET cases_opened = cases_opened + 1, total_spent = total_spent + ?, updated_at = NOW() WHERE citizenid = ?', {
        casePrice, citizenid
    })
end

-- Add case opening to history
function AddCaseHistory(citizenid, caseType, itemWon, itemAmount, casePrice)
    MySQL.insert('INSERT INTO cs_casino_history (citizenid, case_type, item_won, item_amount, case_price) VALUES (?, ?, ?, ?, ?)', {
        citizenid, caseType, itemWon, itemAmount, casePrice
    })
end

-- Add sell transaction to history
function AddSellHistory(citizenid, itemName, itemAmount, sellPrice, originalValue)
    MySQL.insert('INSERT INTO cs_casino_sells (citizenid, item_name, item_amount, sell_price, original_value) VALUES (?, ?, ?, ?, ?)', {
        citizenid, itemName, itemAmount, sellPrice, originalValue
    })
end

-- Get player statistics
function GetPlayerStats(citizenid)
    local playerData = GetPlayerData(citizenid)
    local history = MySQL.query.await('SELECT * FROM cs_casino_history WHERE citizenid = ? ORDER BY created_at DESC LIMIT 10', {citizenid})
    
    return {
        player = playerData,
        recentHistory = history or {}
    }
end

-- Add pending item to database
function AddPendingItem(citizenid, itemId, itemName, itemAmount, sellValue, itemLabel, caseType)
    MySQL.insert('INSERT INTO cs_casino_pending_items (id, citizenid, item_name, item_amount, sell_value, item_label, case_type) VALUES (?, ?, ?, ?, ?, ?, ?)', {
        itemId, citizenid, itemName, itemAmount, sellValue, itemLabel, caseType
    })
end

-- Get pending items for player
function GetPendingItems(citizenid)
    return MySQL.query.await('SELECT * FROM cs_casino_pending_items WHERE citizenid = ? ORDER BY created_at ASC', {citizenid})
end

-- Remove pending item from database
function RemovePendingItem(itemId)
    MySQL.execute('DELETE FROM cs_casino_pending_items WHERE id = ?', {itemId})
end

-- Initialize database on resource start
AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        CreateTables()
    end
end)
