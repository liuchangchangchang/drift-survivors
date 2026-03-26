# Weapon System Module

## Files
- `src/weapons/weapon_data.gd` - Weapon stats from JSON, 4-tier progression
- `src/weapons/weapon_base.gd` - Auto-fire at nearest enemy within range
- `src/weapons/targeting_system.gd` - Static methods to find enemies by range
- `src/weapons/weapon_factory.gd` - Creates weapons from ID, handles merging
- `src/car/weapon_mount.gd` - Single slot, equip/unequip
- `src/car/weapon_mount_manager.gd` - 4 default slots (expandable to 6)

## Weapon Types (data/weapons.json)
pistol, shotgun, smg, sniper, bumper (melee), laser

## Merge System
Two identical weapons at same tier -> merge to next tier (max tier 4).
WeaponMountManager.try_auto_merge() checks all slots.

## Tests
test_weapon_data.gd, test_weapon_base.gd, test_weapon_merge.gd, test_weapon_mount_manager.gd
