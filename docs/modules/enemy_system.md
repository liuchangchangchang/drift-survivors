# Enemy System Module

## Files
- `src/enemies/enemy_data.gd` - Enemy stats from JSON with per-wave scaling
- `src/enemies/enemy_base.gd` - CharacterBody2D, chase AI, damage, death
- `src/enemies/enemy_spawner.gd` - Off-screen spawning, max 100 enemies
- `src/core/hitbox_hurtbox.gd` - Reusable collision components

## Enemy Types (data/enemies.json)
Regular: basic, fast, ranged, heavy, swarm
Elite: brute, charger (spawn based on elite_chance per wave)
Boss: overlord (wave 20)

## Scaling Formula
HP: base_hp * hp_multiplier^(wave-1)
Speed: base_speed * speed_multiplier^(wave-1)

## Tests
test_enemy_data.gd, test_enemy_base.gd, test_enemy_spawner.gd
