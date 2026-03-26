# Drift Survivors - Architecture Overview

## Game Concept
Brotato-style top-down survival game where the player controls a drift racing car with auto-firing weapons. Features arcade drift mechanics with nitro boost system.

## Tech Stack
- Godot 4.6.1 (GDScript)
- GUT 9.6.0 (testing)
- GodotSteam GDExtension (Steam integration)

## Architecture Patterns

### Event Bus
`EventBus` autoload is the central signal hub. All cross-module communication goes through it. Modules never reference each other directly.

### Data-Driven Design
All game tuning lives in `data/*.json` files. `DataLoader` autoload parses them on startup and provides typed accessors.

### State Machine
Generic `StateMachine` + `State` pattern used by:
- `GameManager` (game flow: Menu -> CarSelect -> WeaponSelect -> Playing -> Shop -> ...)
- `DriftStateMachine` (drift stages: None -> Charging1 -> Charging2 -> Ready)

### Object Pooling
`ObjectPool` provides reusable node pools for high-frequency objects (projectiles, enemies, loot drops).

### Component Composition
The car scene uses component nodes (NitroSystem, DriftStateMachine, WeaponMountManager) rather than deep inheritance.

## Autoload Order
1. EventBus - signal hub (no dependencies)
2. DataLoader - JSON data (depends on EventBus)
3. GameManager - game flow FSM (depends on EventBus)
4. AudioManager - sound playback (depends on EventBus)
5. SteamManager - Steam SDK (depends on EventBus)
6. SaveManager - save/load (depends on SteamManager)

## Module Map
| Module | Path | Responsibility |
|--------|------|---------------|
| Core | src/core/ | StateMachine, ObjectPool, hitbox/hurtbox |
| Car | src/car/ | Player car movement, drift, nitro |
| Weapons | src/weapons/ | Auto-fire weapons, projectiles, targeting |
| Enemies | src/enemies/ | Enemy AI, spawning, pooling |
| Waves | src/waves/ | Wave progression, difficulty scaling |
| Economy | src/economy/ | Shop, items, pricing, inventory |
| Stats | src/stats/ | Player stats, modifiers, level-up |
| Loot | src/loot/ | Material drops, pickup magnet |

## Physics Layers
1. Car
2. Enemies
3. Projectiles
4. Loot
5. Arena boundary
6. Hitbox
7. Hurtbox

## Input Map
- WASD / Arrows: accelerate, reverse, steer
- Shift / Space: drift
- E: nitro boost
- Escape: pause
