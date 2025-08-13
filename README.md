# 🎰 CS Casino - Professional FiveM Case Opening System

A comprehensive, secure case opening system for FiveM servers using the QBox framework. Features advanced security, Discord integration, and a modern UI.

![CS Casino Preview](https://img.shields.io/badge/FiveM-CS%20Casino-blue?style=for-the-badge&logo=lua)
![Security](https://img.shields.io/badge/Security-Advanced-green?style=for-the-badge&logo=shield)
![Framework](https://img.shields.io/badge/Framework-QBox-purple?style=for-the-badge)

## ✨ Features

### 🔒 **Advanced Security System**
- **Zero-Trust Architecture** - No client-side item spawning possible
- **Secure Reward System** - Server-only reward validation with temporary IDs
- **Rate Limiting** - Prevents spam and abuse attempts
- **Discord Alerts** - Real-time security violation notifications
- **Input Validation** - Comprehensive parameter sanitization
- **Automatic Bans** - Protection against excessive spam

### 🎨 **Modern User Interface**
- **Professional Design** - Purple theme with glassmorphism effects
- **Smooth Animations** - Case opening with rolling animation
- **Responsive Layout** - Works on all screen sizes
- **Visual Effects** - Particle effects and smooth transitions
- **Inventory Images** - Support for item images from popular inventory systems

### 🎲 **Case Opening System**
- **Multiple Case Types** - Bronze, Silver, Gold, Platinum (fully customizable)
- **Weighted Rewards** - Configurable drop rates and rarities
- **Level Requirements** - Cases unlock as players progress
- **Keep Items** - Players collect items from cases, sell later in Sell Items tab
- **Experience System** - Gain XP and levels from opening cases

### 📊 **Management Features**
- **Clean Configuration** - Easy-to-use config file with examples
- **Case Name Flexibility** - Support for "Silver Case" instead of "silver_case"
- **Backward Compatibility** - Works with existing underscore formats
- **Debug System** - Comprehensive logging for troubleshooting
- **Admin Commands** - Testing and management tools

## 🚀 Installation

### Prerequisites
- **QBox Framework** - This script requires QBox core
- **ox_lib** - For notifications and UI components
- **ox_inventory** - For item management
- **MySQL** - Database for player data and statistics

### Setup Steps

1. **Download** the script and place it in your `resources` folder
2. **Configure Database** - Import the database schema (see Database Setup)
3. **Configure Discord** - Set up webhook for security alerts
4. **Edit Config** - Customize cases, prices, and settings
5. **Start Resource** - Add `ensure CSCasino` to your server.cfg

### Database Setup
```sql
-- Run these SQL commands in your database
CREATE TABLE IF NOT EXISTS `cs_casino_players` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `citizenid` varchar(50) NOT NULL,
  `level` int(11) DEFAULT 1,
  `experience` int(11) DEFAULT 0,
  `total_spent` int(11) DEFAULT 0,
  `total_won` int(11) DEFAULT 0,
  `cases_opened` int(11) DEFAULT 0,
  `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `citizenid` (`citizenid`)
);

-- Additional tables for history and pending items...
```

### Discord Webhook Setup

1. **Open** `server/main.lua`
2. **Find** `DISCORD_WEBHOOK_URL` at the top of the file
3. **Replace** with your Discord webhook URL
4. **Configure** alert settings in `config.lua`

```lua
-- In server/main.lua (line 21)
local DISCORD_WEBHOOK_URL = 'YOUR_WEBHOOK_URL_HERE'
```

## ⚙️ Configuration

### Basic Case Setup
```lua
-- In config.lua
Config.Cases = {
    ['Bronze Case'] = {
        name = 'Bronze Case',
        description = 'Basic tier case with common items',
        price = 100,
        requiredLevel = 1,
        color = '#CD7F32',
        icon = 'fas fa-box',
        items = {
            {item = 'water', weight = 45, min = 1, max = 3},
            {item = 'sandwich', weight = 35, min = 1, max = 2},
            -- ... more items
        }
    },
    -- ... more cases
}
```

### Security Configuration
```lua
Config.Security = {
    enableRateLimiting = true,
    maxEventsPerMinute = 30,
    banOnExcessiveSpam = true,
    spamThreshold = 50,
    
    logging = {
        webhookEnabled = true,
        discordAlerts = {
            enabled = true,
            criticalViolations = true,
            rateLimitViolations = true,
            minimumSeverity = 'WARNING'
        }
    }
}
```

## 🛡️ Security Features

### Exploit Prevention
- **No Client Item Spawning** - Impossible to spawn arbitrary items
- **Secure Reward IDs** - Temporary, validated server-side only
- **Rate Limiting** - Prevents spam and abuse
- **Input Sanitization** - All parameters validated
- **Ownership Validation** - Players can only claim their own rewards

### Discord Security Alerts
Receive instant notifications for:
- 🔴 **Critical Violations** - Invalid reward attempts, fake case types
- 🟡 **Warnings** - Invalid data, malformed parameters
- 🟠 **Rate Limits** - Players exceeding limits
- ⚫ **Bans** - Automatic spam bans

### Example Security Alert
```
🔴 **CRITICAL SECURITY VIOLATION** 🔴

Invalid Reward ID Usage
Player attempted to use unauthorized reward ID

👤 Player: BadPlayer123 (ID: 1)
🔑 Reward ID: fake_reward_123
❌ Error: Invalid reward ID
🕒 Time: 2024-01-15 14:30:22
```

## 🎯 Testing Commands

### Admin Commands (Console Only)
```bash
# Test Discord alerts
casino:testdiscord

# View security status
casino:testsecurity

# Fix player levels
casino:fixlevels
```

### Client Commands
```bash
# Reset UI (if stuck)
casino:resetui

# Spawn NPCs manually
casino:spawnnpcs

# Clean up NPCs
casino:cleannpcs
```

## 📖 Documentation

- **[Security Demonstration](SECURITY_DEMONSTRATION.md)** - Detailed security analysis
- **[Case Naming Guide](CASE_NAMING_GUIDE.md)** - How to use clean case names
- **[Configuration Examples](config.lua)** - Fully commented configuration file

## 🤝 Support

### Common Issues

**"GetCaseData nil value" Error**
- Make sure you're using the latest version
- Restart the resource completely

**Discord Alerts Not Working**
- Check webhook URL in `server/main.lua`
- Verify `webhookEnabled = true` in config
- Use `casino:testdiscord` to test

**Cases Not Opening**
- Check player level requirements
- Verify sufficient funds
- Check server console for security violations

### Getting Help
1. Check the documentation files
2. Review server console for errors
3. Test with admin commands
4. Verify configuration settings

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Credits

- **QBox Framework** - Core functionality
- **ox_lib** - UI components and notifications
- **ox_inventory** - Item management
- **FiveM Community** - Inspiration and support

---

**⚠️ Important Security Note:** This system implements advanced security measures to prevent client-side exploitation. Always keep the Discord webhook URL private and review security logs regularly.

**🎰 Enjoy your secure, professional casino system!**