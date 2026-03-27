extends Node
## Global signal bus for decoupled inter-module communication.
## All game-wide signals are declared here. Modules emit and connect
## to these signals without knowing about each other.

# --- Game Flow ---
signal game_state_changed(old_state: int, new_state: int)
signal wave_started(wave_number: int)
signal wave_ended(wave_number: int)
signal wave_timer_tick(seconds_remaining: float)

# --- Car ---
signal car_damaged(amount: float, source: Node3D)
signal car_healed(amount: float)
signal car_died
signal drift_stage_changed(stage: int) # 0=NONE, 1=CHARGE_1, 2=CHARGE_2, 3=READY
signal nitro_activated
signal nitro_depleted
signal nitro_gauge_changed(value: float) # 0.0 to 1.0

# --- Combat ---
signal enemy_spawned(enemy: Node3D)
signal enemy_killed(enemy: Node3D, pos: Vector3, material_value: int)
signal enemy_damaged(enemy: Node3D, amount: float, source: String)
signal weapon_fired(weapon_id: String)
signal weapon_merged(weapon_id: String, new_tier: int)
signal weapon_equipped(slot: int, weapon_id: String)
signal weapon_unequipped(slot: int)

# --- Economy ---
signal material_collected(amount: int)
signal material_spent(amount: int)
signal material_changed(new_total: int)
signal item_purchased(item_id: String)
signal shop_opened
signal shop_closed

# --- Progression ---
signal xp_gained(amount: int)
signal level_up(new_level: int)
signal upgrade_chosen(upgrade_id: String)
signal stat_changed(stat_name: String, old_value: float, new_value: float)

# --- System ---
signal data_loaded
signal save_completed
signal achievement_unlocked(achievement_id: String)
