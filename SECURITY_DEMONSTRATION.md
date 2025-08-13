# CS Casino Security Demonstration

## Overview
This document demonstrates how the new secure reward system prevents client-side exploitation and ensures that players cannot spawn arbitrary items.

## Security Issues BEFORE Implementation

### The Vulnerability
Before the security fix, the client could send direct item data to the server:

```lua
-- INSECURE - Client could send this:
TriggerServerEvent('cs-casino:server:finalizeCase', {
    item = 'money', 
    amount = 100000000, 
    action = 'add'
})
```

**This allowed players to:**
- Spawn any item with any quantity
- Bypass case opening mechanics
- Get items they never won
- Crash servers with invalid item names
- Manipulate economy

## Security Implementation AFTER Fix

### 1. Secure Reward Table (Server-Only)
```lua
-- Server-side only - clients cannot access or modify
local activeRewards = {} -- Indexed by secure IDs
local rewardIdCounter = 0

-- Example reward structure:
-- activeRewards["player123_1640995200_1"] = {
--     citizenid = "player123",
--     item = "weapon_pistol", 
--     amount = 1,
--     caseType = "gold_case",
--     created = 1640995200,
--     used = false
-- }
```

### 2. Secure ID Generation
When a case is opened, the server:
1. Generates the reward internally
2. Creates a unique, time-based reward ID
3. Stores the reward securely on server
4. Sends ONLY the ID to client (no item data)

```lua
-- Server generates secure reward
local rewardId = CreateSecureReward(citizenid, "weapon_pistol", 1, "gold_case")
-- Result: "player123_1640995200_1"

-- Send to client (NO exploitable data)
TriggerClientEvent('cs-casino:client:caseOpened', src, {
    success = true,
    rewardId = rewardId,  -- Secure ID only
    -- displayItem/displayAmount only for UI (can't be exploited)
    displayItem = "weapon_pistol",
    displayAmount = 1
})
```

### 3. Secure Validation & Consumption
When client makes a choice, server validates everything:

```lua
-- Client can ONLY send:
TriggerServerEvent('cs-casino:server:finalizeCase', {
    action = 'keep',  -- or 'sell'
    rewardId = 'player123_1640995200_1'
})

-- Server validates:
-- 1. Does reward ID exist?
-- 2. Does it belong to this player?
-- 3. Has it been used already?
-- 4. Is it expired (30 min max)?
-- 5. Is the action valid ('keep' or 'sell')?
```

## Attack Prevention Examples

### Attack 1: Item Spawning
```lua
-- ❌ BLOCKED - Client tries to spawn money
TriggerServerEvent('cs-casino:server:finalizeCase', {
    item = 'money', 
    amount = 100000000,
    action = 'keep'
})
```
**Result:** Server logs security violation, player gets warning, no items given.

### Attack 2: Fake Reward ID
```lua
-- ❌ BLOCKED - Client tries fake reward ID
TriggerServerEvent('cs-casino:server:finalizeCase', {
    action = 'keep',
    rewardId = 'fake_reward_123'
})
```
**Result:** Server validates reward ID, finds it invalid, logs security violation.

### Attack 3: Using Someone Else's Reward
```lua
-- ❌ BLOCKED - Player A tries to use Player B's reward
-- Player A tries: rewardId = 'playerB_1640995200_1'
```
**Result:** Server checks citizenid ownership, blocks unauthorized access.

### Attack 4: Replay Attack
```lua
-- ❌ BLOCKED - Player tries to reuse consumed reward
-- Player tries same rewardId twice
```
**Result:** Server checks if reward was already used, blocks duplicate usage.

### Attack 5: Rate Limit Bypass
```lua
-- ❌ BLOCKED - Player spams finalizeCase events
-- Player sends 100 requests per minute
```
**Result:** Rate limiting kicks in, player gets cooldown, excessive spam leads to ban.

## Security Features

### ✅ Server-Side Validation
- All rewards generated and validated on server only
- No client input trusted for item data
- Comprehensive input validation

### ✅ Secure ID System  
- Time-based unique IDs prevent prediction
- Cross-player access blocked
- Automatic expiration (30 minutes)
- One-time use only

### ✅ Rate Limiting
- Event-specific limits prevent spam
- Escalating consequences (warnings → cooldowns → bans)
- Discord webhook alerts for admins

### ✅ Audit Trail
- All actions logged with player identification
- Security violations tracked and reported
- Webhook integration for real-time alerts

### ✅ Automatic Cleanup
- Old/used rewards automatically removed
- Memory efficient design
- No permanent storage of reward IDs

## Testing the Security

### Test 1: Verify Normal Operation
1. Open a case normally
2. Receive reward ID from server  
3. Choose keep/sell - should work normally

### Test 2: Attempt Item Spawning
1. Try sending finalizeCase with fake item data
2. Should receive security violation notification
3. No items should be received

### Test 3: Attempt Reward ID Manipulation
1. Try using invalid/fake reward IDs
2. Try using expired reward IDs
3. Try using another player's reward ID
4. All should be blocked with security violations

### Test 4: Rate Limit Testing
1. Spam finalizeCase events rapidly
2. Should receive rate limit warnings
3. Should trigger cooldowns
4. Excessive spam should trigger ban

## Discord Security Alerts 🚨

### Enhanced Real-Time Monitoring
The system now sends detailed Discord webhook alerts for all security violations:

#### Alert Types
- 🔴 **CRITICAL VIOLATIONS** - Invalid reward ID usage, fake case types
- 🟡 **WARNINGS** - Invalid data structures, malformed parameters  
- 🟠 **RATE LIMITS** - Players exceeding event limits
- ⚫ **BANS** - Players banned for excessive spam

#### Example Discord Alert
```
🔴 **CRITICAL SECURITY VIOLATION** 🔴

Invalid Reward ID Usage
Player attempted to use invalid/expired/unauthorized reward ID

👤 Player Information
Name: BadPlayer123
ID: 1
License: license:abc123def456
CitizenID: CIT123456

⚠️ Violation Type: Invalid Reward ID Usage
🎯 Attempted Action: finalizeCase  
🚨 Severity Level: CRITICAL
🔑 Reward ID: `fake_reward_123`
❌ Error Details: `Invalid reward ID`
🕒 Timestamp: 2024-01-15 14:30:22
```

#### Alert Configuration
```lua
-- In config.lua
discordAlerts = {
    enabled = true,                     -- Enable enhanced Discord security alerts
    criticalViolations = true,          -- Send critical security violations
    rateLimitViolations = true,         -- Send rate limit violations  
    invalidDataAttempts = true,         -- Send invalid data structure attempts
    invalidCaseTypes = true,            -- Send invalid case type attempts
    invalidRewardIds = true,            -- Send invalid reward ID attempts
    invalidActions = true,              -- Send invalid action attempts
    successfulTransactions = false,     -- Send successful case finalizations (can be spammy)
    playerBans = true,                  -- Send player ban notifications
    
    -- Alert filtering
    minimumSeverity = 'WARNING',        -- Minimum severity: INFO, WARNING, CRITICAL
    rateLimitCooldown = 300,           -- Seconds between similar alerts (prevents spam)
    maxAlertsPerHour = 50,             -- Maximum alerts per hour to prevent spam
}
```

#### Smart Alert Filtering
- **Severity Filtering**: Only send alerts above configured severity level
- **Rate Limiting**: Prevent spam by limiting similar alerts per player
- **Hourly Limits**: Maximum alerts per hour to prevent Discord channel spam
- **Type Filtering**: Enable/disable specific violation types
- **Cooldown System**: Prevents duplicate alerts for same player/violation

### Discord Webhook Setup
1. **Configure Webhook URL in server/main.lua**:
   ```lua
   -- At the top of server/main.lua
   local DISCORD_WEBHOOK_URL = 'YOUR_WEBHOOK_URL_HERE'
   ```

2. **Enable/Disable Features in config.lua**:
   ```lua
   webhookEnabled = true,          -- Master webhook switch
   discordAlerts = {
       enabled = true,             -- Enable enhanced alerts
       criticalViolations = true,  -- Critical security violations
       rateLimitViolations = true, -- Rate limit violations
       -- ... other settings
   }
   ```

### Testing Commands
- `casino:testdiscord` - Send test Discord alert to verify integration
- `casino:testsecurity` - View current security system status

## Benefits of This System

1. **Complete Prevention** of item spawning exploits
2. **Zero Trust** client architecture 
3. **Automatic Security** without admin intervention
4. **Detailed Logging** for security analysis
5. **Performance Efficient** with automatic cleanup
6. **Backward Compatible** with existing UI
7. **Real-time Discord Alerts** with smart filtering
8. **Comprehensive Monitoring** of all security events

## Conclusion

The secure reward system completely eliminates the ability for clients to spawn arbitrary items or manipulate the case opening system. All rewards are pre-defined and validated on the server, with clients only able to reference them through secure, temporary IDs.

**No client input is trusted for item data, making exploitation impossible.**
