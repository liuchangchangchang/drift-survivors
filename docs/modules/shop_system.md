# Shop & Economy Module

## Files
- `src/economy/economy_manager.gd` - Material (currency) tracking
- `src/economy/shop_manager.gd` - 4 random items per wave, buy/reroll/lock
- `src/economy/item_rarity.gd` - Luck-weighted rarity selection
- `src/economy/inventory.gd` - Item stack tracking with max limits
- `src/stats/stat_modifier.gd` - Flat/percent modifiers
- `src/stats/stat_calculator.gd` - Aggregates all modifiers: (base+flat)*(1+percent)
- `src/stats/player_stats.gd` - Central stat store with source tracking
- `src/stats/level_up_manager.gd` - XP thresholds, 3 upgrade choices

## Pricing Formula
price = base_price * 1.08^(wave-1)
Reroll cost: 5 + reroll_count * 2

## Rarity by Wave
Common: wave 1+, Uncommon: wave 2+ (max 60%), Rare: wave 4+ (max 25%), Legendary: wave 8+ (max 8%)
Luck stat increases all rarity chances up to 2x.

## Tests
test_stat_system.gd, test_economy.gd, test_inventory.gd, test_shop_manager.gd, test_level_up.gd
