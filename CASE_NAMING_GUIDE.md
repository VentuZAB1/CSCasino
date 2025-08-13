# CS Casino Case Naming Guide

## Overview
The CS Casino now supports clean, professional case names without underscores! No more `silver_case` - just use `Silver Case` and it displays beautifully in the UI.

## ✅ New Clean Format (Recommended)

### Configuration Example
```lua
-- In config.lua
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
            -- ... more items
        }
    },
    ['Silver Case'] = {
        name = 'Silver Case',
        description = 'Medium tier case with uncommon items',
        price = 250,
        requiredLevel = 5,
        color = '#C0C0C0',
        icon = 'fas fa-cube',
        -- ... items
    },
    ['Gold Case'] = {
        name = 'Gold Case',
        description = 'High tier case with rare items',
        price = 500,
        requiredLevel = 15,
        color = '#FFD700',
        icon = 'fas fa-gift',
        -- ... items
    },
    ['Platinum Case'] = {
        name = 'Platinum Case',
        description = 'Premium tier case with legendary items',
        price = 1000,
        requiredLevel = 30,
        color = '#E5E4E2',
        icon = 'fas fa-crown',
        -- ... items
    }
}
```

### How It Looks in UI
- ✅ **Bronze Case** (clean and professional)
- ✅ **Silver Case** (easy to read)
- ✅ **Gold Case** (looks great)
- ✅ **Platinum Case** (premium feel)

## 🔄 Backward Compatibility

The system still supports the old underscore format for existing configurations:

### Old Format Still Works
```lua
-- These still work, but not recommended for new configs
Config.Cases = {
    ['bronze_case'] = {
        name = 'Bronze Case',
        -- ... config
    },
    ['silver_case'] = {
        name = 'Silver Case', 
        -- ... config
    }
}
```

### Automatic Conversion
The server automatically handles conversion between formats:
- `bronze_case` → `Bronze Case`
- `silver_case` → `Silver Case`
- `gold_case` → `Gold Case`
- `platinum_case` → `Platinum Case`

## 🎨 Custom Case Examples

Here are some creative case name examples using the new clean format:

### Theme-Based Cases
```lua
['Weapon Crate'] = {
    name = 'Weapon Crate',
    description = 'Military-grade weapons and attachments',
    price = 750,
    color = '#2F4F2F',
    icon = 'fas fa-crosshairs'
},

['Medical Supplies'] = {
    name = 'Medical Supplies', 
    description = 'Emergency medical equipment and drugs',
    price = 300,
    color = '#DC143C',
    icon = 'fas fa-medkit'
},

['Street Gear'] = {
    name = 'Street Gear',
    description = 'Underground items for city life',
    price = 150,
    color = '#696969',
    icon = 'fas fa-mask'
},

['VIP Package'] = {
    name = 'VIP Package',
    description = 'Exclusive luxury items for high-rollers',
    price = 2500,
    color = '#8A2BE2',
    icon = 'fas fa-star'
}
```

### Seasonal Cases
```lua
['Holiday Special'] = {
    name = 'Holiday Special',
    description = 'Limited-time festive items',
    price = 400,
    color = '#FF6347',
    icon = 'fas fa-gift'
},

['Summer Bundle'] = {
    name = 'Summer Bundle',
    description = 'Beach and vacation themed items',
    price = 350,
    color = '#FFD700',
    icon = 'fas fa-sun'
},

['Winter Collection'] = {
    name = 'Winter Collection',
    description = 'Cold weather gear and items',
    price = 450,
    color = '#87CEEB',
    icon = 'fas fa-snowflake'
}
```

## 🛠️ Technical Details

### Server-Side Compatibility Functions
```lua
-- Automatically handles both formats
local function NormalizeCaseName(caseType)
    -- Converts "bronze_case" to "Bronze Case"
end

local function GetCaseData(caseType)
    -- Finds case data regardless of format
end
```

### Client-Side Display Functions
```javascript
// Automatically formats case names for display
formatCaseName(caseType) {
    return caseType
        .replace(/_/g, ' ')  // Remove underscores
        .replace(/\b\w/g, l => l.toUpperCase());  // Capitalize words
}
```

## 📋 Migration Guide

### For Existing Configurations
1. **Keep using your current config** - everything still works
2. **Gradually update** case names when making changes
3. **No rush** - both formats work simultaneously

### For New Configurations
1. **Use clean names** like `Silver Case` instead of `silver_case`
2. **Follow naming conventions**:
   - Capitalize first letter of each word
   - Use spaces instead of underscores
   - Keep names concise but descriptive

### Example Migration
```lua
-- OLD (still works)
['bronze_case'] = {
    name = 'Bronze Case',
    -- ... config
}

-- NEW (recommended)
['Bronze Case'] = {
    name = 'Bronze Case',
    -- ... config  
}
```

## ✨ Benefits

1. **Professional Appearance** - Clean names look better in UI
2. **Better User Experience** - Easier to read and understand
3. **Flexible Naming** - Support for any case name format
4. **Backward Compatible** - Existing configs continue working
5. **Future Proof** - Modern naming convention

## 🚀 Best Practices

### Naming Conventions
- Use **Title Case** (Bronze Case, not bronze case)
- Keep names **descriptive** but **concise**
- Use **spaces** instead of underscores
- Consider **theme consistency** across your cases

### UI Considerations
- Names display exactly as configured
- Longer names still fit in UI design
- Icons and colors help distinguish cases
- Consistent styling across all cases

### Configuration Tips
- Group similar cases together in config
- Use consistent pricing tiers
- Match case names with their rarity/value
- Test case names in UI before going live

The new clean case naming system makes your casino look more professional while maintaining full backward compatibility with existing configurations!
