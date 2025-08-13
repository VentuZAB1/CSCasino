Config = {}

-- General Settings
 -- Debug Settings - Comprehensive debugging system
Config.Debug = {
    enabled = false,                    -- Master debug switch (turns all debug on/off)
    
    -- Server-side debugging
    server = {
        events = false,                 -- Debug server events (RegisterNetEvent)
        database = false,               -- Debug database queries and operations
        playerActions = false,          -- Debug player actions (case opening, selling, etc.)
        security = false,               -- Debug security system (rate limiting, validation)
        itemOperations = false,         -- Debug item giving/removing operations
        levelSystem = false,            -- Debug XP and level calculations
        moneyTransactions = false,      -- Debug money operations
    },
    
    -- Client-side debugging  
    client = {
        interactions = false,           -- Debug ox_lib/ox_target interactions
        ui = false,                     -- Debug UI opening/closing
        events = false,                 -- Debug client events
        blips = false,                  -- Debug blip creation/management
        npcs = false,                   -- Debug NPC spawning
    },
    
    -- UI/NUI debugging
    ui = {
        messages = false,               -- Debug NUI message receiving
        functions = false,              -- Debug function calls and data processing
        animations = false,             -- Debug case opening animations
        dataDisplay = false,            -- Debug data display functions
        userInteractions = false,       -- Debug button clicks and user actions
    }
}
Config.DefaultLevel = 1
Config.MaxLevel = 50
Config.SellMargin = 0.03 -- 3% margin when selling items back

-- Currency Settings
Config.Currency = 'bank' -- 'cash' or 'bank'

-- Branding Settings
Config.Branding = {
    name = 'RockFordGingers',                -- Casino name displayed in header
    icon = 'fas fa-crown',                   -- FontAwesome icon class
    colors = {
        primary = '#ffd700',                 -- Gold - main brand color
        secondary = '#ff6b35',               -- Orange - secondary brand color  
        accent1 = '#8b45c1',                 -- Purple - accent color 1
        accent2 = '#c084fc'                  -- Light Purple - accent color 2
    },
    textStyle = {
        fontFamily = 'Inter',                -- Font: 'Inter', 'Orbitron', 'Arial', etc.
        fontSize = 32,                       -- Text size in pixels
        fontWeight = 800,                    -- Font weight: 100-900
        letterSpacing = 1,                   -- Letter spacing in pixels
        textTransform = 'uppercase',         -- Text transform: 'uppercase', 'lowercase', 'capitalize', 'none'
        animation = true                     -- Enable animated gradient effect
    },
    iconStyle = {
        size = 36,                          -- Icon size in pixels
        glowEffect = true,                  -- Enable pulsing glow animation
        gradientIcon = true                 -- Use gradient colors for icon (vs solid color)
    }
}

-- Titles and Text Configuration
Config.Titles = {
    -- Casino Names
    casinoName = 'RockFordGingers',          -- Main casino name (same as branding.name)
    casinoShortName = 'RFG Casino',          -- Short version for notifications
    
    -- UI Titles
    windowTitle = 'RockFordGingers Casino',   -- Browser window title
    headerTitle = 'RockFordGingers',         -- Main header title
    
    -- Interaction Text
    openLabel = 'Open RockFordGingers Casino', -- ox_lib/ox_target interaction label
    accessLabel = 'Access RFG Casino',        -- Secondary interaction label
    
    -- Notification Messages
    notifications = {
        welcome = 'Welcome to RockFordGingers Casino!',
        insufficientFunds = 'Insufficient funds!',
        invalidCase = 'Invalid case type!',
        mustBeNearCasino = 'You must be near the casino to access it!',
        levelRequired = 'Level {level} required to open this case!',
        caseOpened = 'Case opened successfully!',
        itemCollected = 'Item collected: {item}',
        itemSold = 'Item sold for ${amount}',
        itemKept = 'Item added to inventory',
        errorOccurred = 'An error occurred. Please try again.',
        rateLimited = 'Please slow down!',
        cooldownActive = 'Cooldown active! Try again in {time}.',
        securityViolation = 'Security violation detected!',
    },
    
    -- Blip Labels
    blipLabels = {
        mainCasino = 'RockFordGingers Casino',
        casinoEntrance = 'Casino Entrance',
        casinoInterior = 'Casino Gaming Area'
    },
    
    -- Security System
    security = {
        systemName = 'RFG Casino Security',
        alertTitle = '🚨 RFG Casino Security Alert',
        webhookUsername = 'RFG Casino Security',
        banMessage = 'RFG Casino: Security violation detected',
        logPrefix = '[RFG Casino Security]'
    },
    
    -- Case Opening
    caseOpening = {
        rolling = 'Rolling...',
        congratulations = 'Congratulations!',
        youWon = 'You won:',
        collectButton = 'Collect Item',
        collecting = 'Collecting...',
        openingCase = 'Opening {case}...',
        caseResult = 'Case Result'
    },
    
    -- Inventory & Selling
    inventory = {
        pendingTitle = 'Pending Items',
        sellableTitle = 'Sellable Items',
        keepButton = 'Keep',
        sellButton = 'Sell',
        sellAllButton = 'Sell All',
        keeping = 'Keeping...',
        selling = 'Selling...',
        noItems = 'No items available',
        totalValue = 'Total Value: ${amount}'
    },
    
    -- Stats & Level
    stats = {
        levelLabel = 'Level',
        xpLabel = 'XP',
        casesOpenedLabel = 'Cases Opened',
        totalSpentLabel = 'Total Spent',
        totalWonLabel = 'Total Won'
    }
}

--[[
    Branding Customization Examples:
    
    Popular Icon Options:
    - 'fas fa-crown'         (Crown - premium/royal theme)
    - 'fas fa-dice'          (Dice - classic casino theme)
    - 'fas fa-gem'           (Gem - luxury theme)
    - 'fas fa-star'          (Star - achievement theme)
    - 'fas fa-fire'          (Fire - energy theme)
    - 'fas fa-bolt'          (Lightning - power theme)
    
    Font Family Options:
    - 'Inter'                (Modern, clean)
    - 'Orbitron'            (Futuristic, sci-fi)
    - 'Arial'               (Classic, readable)
    - 'Roboto'              (Google font, modern)
    
    Color Scheme Examples:
    Gold & Orange:    primary: '#ffd700', secondary: '#ff6b35'
    Blue & Cyan:      primary: '#0ea5e9', secondary: '#06b6d4'  
    Green & Lime:     primary: '#10b981', secondary: '#84cc16'
    Red & Pink:       primary: '#ef4444', secondary: '#ec4899'
--]]

-- Interaction Settings
Config.InteractionType = 'ox_lib' -- 'ox_lib', 'ox_target', or 'both'
-- ox_lib: Press [E] to interact with TextUI
-- ox_target: Click to interact with target zones
-- both: Enable both interaction methods

-- Security Settings
Config.Security = {
    enableRateLimiting = true,          -- Enable event rate limiting
    maxEventsPerMinute = 30,            -- Maximum events per player per minute
    banOnExcessiveSpam = true,          -- Ban players who spam events
    spamThreshold = 50,                 -- Events per minute to trigger ban
    
    -- Event-specific rate limits
    eventLimits = {
        ['cs-casino:server:openCase'] = 10,      -- Max 10 case opens per minute
        ['cs-casino:server:collectItem'] = 20,   -- Max 20 item collections per minute
        ['cs-casino:server:sellItem'] = 15,      -- Max 15 item sells per minute
        ['cs-casino:server:keepPendingItem'] = 20,
        ['cs-casino:server:sellPendingItem'] = 20,
        ['cs-casino:server:finalizeCase'] = 25,  -- Max 25 case finalizations per minute
    },
    
    -- Input validation settings
    validation = {
        maxStringLength = 100,          -- Maximum string parameter length
        allowedCaseTypes = true,        -- Only allow configured case types
        validateItemNames = true,       -- Validate item names against game items
        checkPlayerPosition = false,    -- Enable position validation (set coords if enabled)
        casinoCoords = vector3(925.3, 46.9, 81.1), -- Casino location for position checks
        maxDistance = 100.0,            -- Maximum distance from casino
    },
    
    -- Logging settings
    logging = {
        enabled = true,                 -- Enable security logging
        logAttempts = true,             -- Log attempted exploits
        logValidActions = false,        -- Log valid actions (for debugging)
        -- NOTE: Discord webhook URL is now configured in server/main.lua at the top
        webhookEnabled = true,          -- Enable/disable webhook notifications
        webhookOnWarnings = true,       -- Send warnings to webhook
        webhookOnErrors = true,         -- Send errors to webhook
        webhookOnBans = true,           -- Send ban notifications to webhook
        
        -- Enhanced Discord alert settings
        discordAlerts = {
            enabled = true,                     -- Enable enhanced Discord security alerts
            criticalViolations = true,          -- Send critical security violations
            rateLimitViolations = true,         -- Send rate limit violations  
            invalidDataAttempts = true,         -- Send invalid data structure attempts
            invalidCaseTypes = true,            -- Send invalid case type attempts
            invalidRewardIds = true,            -- Send invalid reward ID attempts
            invalidActions = true,              -- Send invalid action attempts
            successfulTransactions = false,    -- Send successful case finalizations (can be spammy)
            playerBans = true,                  -- Send player ban notifications
            
            -- Alert filtering
            minimumSeverity = 'WARNING',        -- Minimum severity: INFO, WARNING, CRITICAL
            rateLimitCooldown = 300,           -- Seconds between similar alerts (prevents spam)
            maxAlertsPerHour = 50,             -- Maximum alerts per hour to prevent spam
        }
    }
}

--[[
    Discord Webhook Setup Instructions:
    
    ** IMPORTANT: Discord webhook URL is now configured in server/main.lua at the top **
    
    1. Create a Discord channel for casino security alerts
    2. Go to Channel Settings > Integrations > Webhooks
    3. Click "Create Webhook"
    4. Copy the webhook URL
    5. Open server/main.lua and find DISCORD_WEBHOOK_URL at the top
    6. Replace the URL with your webhook URL
    7. Save and restart the resource
    
    Example webhook URL format:
    https://discord.com/api/webhooks/1234567890123456789/AbCdEfGhIjKlMnOpQrStUvWxYz1234567890
    
    The webhook will send enhanced security alerts:
    - 🔴 Critical: Invalid reward IDs, fake case types
    - 🟡 Warnings: Invalid data, malformed parameters
    - 🟠 Rate Limits: Players exceeding limits
    - ⚫ Bans: Players banned for spam
    
    Each alert includes detailed player info, violation details, and context.
--]]

-- Level System
Config.LevelSystem = {
    xpPerCase = 50,
    xpRequiredBase = 1000,
    xpMultiplier = 1.5 -- Each level requires 1.5x more XP than previous
}

-- Case Types and Pricing
Config.Cases = {
    ['Bronze Case'] = {
        name = 'Bronze Case',
        description = 'Basic tier case with common FiveM items',
        price = 100,
        requiredLevel = 1,
        color = '#CD7F32',
        icon = 'fas fa-box',
        items = {
            {item = 'water', weight = 45, min = 1, max = 3},
            {item = 'sandwich', weight = 35, min = 1, max = 2},
            {item = 'phone', weight = 15, min = 1, max = 1},
            {item = 'radio', weight = 5, min = 1, max = 1}
        }
    },
    ['Silver Case'] = {
        name = 'Silver Case',
        description = 'Medium tier case with uncommon items',
        price = 250,
        requiredLevel = 5,
        color = '#C0C0C0',
        icon = 'fas fa-cube',
        items = {
            {item = 'lockpick', weight = 30, min = 1, max = 2},
            {item = 'bandage', weight = 25, min = 2, max = 5},
            {item = 'repairkit', weight = 20, min = 1, max = 2},
            {item = 'weapon_knife', weight = 15, min = 1, max = 1},
            {item = 'gps', weight = 10, min = 1, max = 1}
        }
    },
    ['Gold Case'] = {
        name = 'Gold Case',
        description = 'High tier case with rare items',
        price = 500,
        requiredLevel = 15,
        color = '#FFD700',
        icon = 'fas fa-gift',
        items = {
            {item = 'weapon_pistol', weight = 25, min = 1, max = 1},
            {item = 'armor', weight = 20, min = 1, max = 2},
            {item = 'advancedlockpick', weight = 20, min = 1, max = 1},
            {item = 'thermite', weight = 15, min = 1, max = 1},
            {item = 'laptop', weight = 10, min = 1, max = 1},
            {item = 'goldbar', weight = 5, min = 1, max = 2},
            {item = 'diamond', weight = 5, min = 1, max = 1}
        }
    },
    ['Platinum Case'] = {
        name = 'Platinum Case',
        description = 'Premium tier case with legendary items',
        price = 1000,
        requiredLevel = 30,
        color = '#E5E4E2',
        icon = 'fas fa-crown',
        items = {
            {item = 'weapon_assaultrifle', weight = 15, min = 1, max = 1},
            {item = 'weapon_carbinerifle', weight = 15, min = 1, max = 1},
            {item = 'security_card_01', weight = 20, min = 1, max = 1},
            {item = 'rolex', weight = 15, min = 1, max = 1},
            {item = 'diamond_ring', weight = 10, min = 1, max = 1},
            {item = 'goldchain', weight = 10, min = 1, max = 2},
            {item = 'markedbills', weight = 10, min = 1, max = 5},
            {item = 'cryptostick', weight = 5, min = 1, max = 1}
        }
    }
}

--[[
    Case Icon Examples:
    You can use any FontAwesome 5 icon for your cases. Here are some popular choices:
    
    Basic/Common Cases:
    - 'fas fa-box'           (Basic box)
    - 'fas fa-cube'          (Simple cube)
    - 'fas fa-archive'       (Archive box)
    
    Medium/Rare Cases:
    - 'fas fa-gift'          (Gift box)
    - 'fas fa-briefcase'     (Briefcase)
    - 'fas fa-suitcase'      (Suitcase)
    
    Premium/Legendary Cases:
    - 'fas fa-crown'         (Crown)
    - 'fas fa-gem'           (Gem)
    - 'fas fa-trophy'        (Trophy)
    - 'fas fa-star'          (Star)
    
    Special Theme Cases:
    - 'fas fa-skull'         (Dark/Gothic theme)
    - 'fas fa-fire'          (Fire theme)
    - 'fas fa-bolt'          (Electric theme)
    - 'fas fa-magic'         (Magic theme)
    - 'fas fa-rocket'        (Space theme)
    
    Remember to use the full FontAwesome class (fas fa-iconname)
--]]

-- Casino Interior Settings
Config.CasinoInterior = {
    enabled = false,                     -- Enable/disable casino interior teleportation
    entranceCoords = vector3(925.3, 46.9, 81.1),        -- Outside casino entrance
    interiorCoords = vector3(1089.0, 206.0, -49.0),     -- Inside casino (Diamond Casino interior)
    teleportMessage = 'Press [E] to enter Casino Interior',
    exitMessage = 'Press [E] to exit Casino'
}

-- Casino Interaction Locations
Config.CasinoLocations = {
    {
        coords = vector3(925.3, 46.9, 81.1), -- Casino main entrance
        radius = 2.0,
        label = 'openLabel',             -- References Config.Titles.openLabel
        icon = 'fas fa-dice',
        useBlip = true,
        blipSprite = 617,
        blipColor = 5,
        blipScale = 0.8,
        blipLabel = 'mainCasino'         -- References Config.Titles.blipLabels.mainCasino
    }
}

-- Add interior location if enabled
if Config.CasinoInterior.enabled then
    table.insert(Config.CasinoLocations, {
        coords = Config.CasinoInterior.interiorCoords,
        radius = 1.5,
        label = 'accessLabel',           -- References Config.Titles.accessLabel
        icon = 'fas fa-coins',
        useBlip = false
    })
end

-- NPC Locations (Optional - for physical casino locations)
Config.NPCLocations = {
    {
        coords = vector4(1037.9501, 181.3354, 81.0025, 61.2036),
        model = 's_m_y_casino_01',
        scenario = 'WORLD_HUMAN_STAND_IMPATIENT'
    }
}

-- UI Settings
Config.UI = {
    primaryColor = '#8b45c1',
    secondaryColor = '#9333ea',
    backgroundColor = 'rgba(255, 255, 255, 0.1)',
    animationDuration = 2000, -- Case opening animation duration in ms
    particleEffects = true
}

-- Inventory Image Settings
Config.InventoryImages = {
    enabled = true,
    resourceName = 'ox_inventory', -- Resource name where images are stored
    imagePath = 'web/images/', -- Path within the resource to images folder
    imageFormat = '.png', -- Image file format (.png, .jpg, .webp, etc.)
    fallbackIcon = 'fas fa-cube', -- Fallback icon if image not found
    
    -- Custom image mappings (optional - for items with different image names)
    customMappings = {
        -- ['item_name'] = 'custom_image_name.png',
        -- ['weapon_pistol'] = 'weapons/pistol.png',
        -- ['money'] = 'cash.png',
    },
    
    -- Alternative image sources (will try these if main path fails)
    alternativePaths = {
        'nui://qb-inventory/html/images/',
        'nui://lj-inventory/html/images/',
        'nui://qs-inventory/html/images/',
    }
}
