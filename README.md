# Drift Survivors

A Brotato-style top-down survival game where you control a drift racing car with auto-firing weapons. Survive 20 waves of enemies, upgrade your car and weapons in the shop between waves, and master the drift-nitro mechanics to dominate.

## Features

- **Arcade Drift Racing**: QQ Speed / KartRider-style drift with nitro boost
- **4-Stage Drift System**: Longer drifts charge bigger nitro boosts
- **Auto-Fire Weapons**: 6 weapon types across 4 tiers, mounted on your car
- **Weapon Merging**: Two identical weapons merge into a stronger version
- **20-Wave Survival**: Progressive difficulty with elite enemies and a final boss
- **Between-Wave Shop**: Buy items, upgrade stats, expand weapon slots
- **Level-Up Upgrades**: Choose from random upgrades on each level up

## Tech Stack

- **Engine**: Godot 4.6.1 (GDScript)
- **Testing**: GUT 9.6.0 (223+ unit tests)
- **Steam**: GodotSteam GDExtension (ready for integration)

## Project Structure

```
src/
  autoload/    # Singletons: EventBus, GameManager, DataLoader, etc.
  core/        # StateMachine, ObjectPool, HitboxHurtbox
  car/         # Player car, drift, nitro, weapon mounts
  weapons/     # Weapon system, targeting, factory, merging
  enemies/     # Enemy AI, spawning, data scaling
  waves/       # Wave manager, difficulty curves
  economy/     # Shop, inventory, item rarity
  stats/       # Stat modifiers, player stats, level-up
  loot/        # Material drops, magnet pickup
  ui/          # All UI screen scripts
  game/        # Game arena integration
data/          # JSON game data (cars, weapons, enemies, items, waves)
scenes/        # Godot scene files
test/          # GUT unit tests
docs/          # Architecture documentation
```

## Running Tests

```bash
godot --headless -s --path . addons/gut/gut_cmdln.gd -gdir=res://test/unit/ -gexit
```

## Controls

| Action | Key |
|--------|-----|
| Accelerate | W / Up Arrow |
| Reverse | S / Down Arrow |
| Steer Left | A / Left Arrow |
| Steer Right | D / Right Arrow |
| Drift | Left Shift / Space |
| Nitro Boost | E |
| Pause | Escape |

## Architecture

See `docs/architecture_overview.md` for full details. Key patterns:
- **Event Bus**: Decoupled communication via global signals
- **Data-Driven**: All game tuning in JSON files
- **Component Composition**: Car uses components (DriftSM, NitroSystem, WeaponMounts)
- **Object Pooling**: Efficient reuse for projectiles, enemies, loot
