class_name CarStats
extends Resource
## Holds base stats for a car. Loaded from JSON data.
## Uses 3D unit-scale values (not pixel-scale).

# Health
@export var max_hp: float = 100.0
@export var hp_regen: float = 1.0
@export var armor: float = 0.0

# Movement (3D absolute direction)
@export var base_accel: float = 12.0
@export var max_speed: float = 25.0
@export var boost_speed: float = 37.5
@export var friction: float = 0.96
@export var normal_grip: float = 0.15
@export var drift_grip: float = 0.015
@export var turn_speed_normal: float = 5.0
@export var turn_speed_drift: float = 10.0

# Drift charge
@export var charge_rate: float = 30.0
@export var max_charge: float = 100.0
@export var boost_duration: float = 1.0

# Nitro
@export var nitro_max: float = 100.0
@export var nitro_accumulation_rate: float = 10.0
@export var nitro_drain_rate: float = 25.0
@export var nitro_damage: float = 30.0

# Equipment
@export var weapon_slots: int = 4

static func from_dict(data: Dictionary) -> CarStats:
	var stats := CarStats.new()
	stats.max_hp = data.get("max_hp", 100.0)
	stats.hp_regen = data.get("hp_regen", 1.0)
	stats.armor = data.get("armor", 0.0)
	stats.base_accel = data.get("base_accel", 12.0)
	stats.max_speed = data.get("max_speed", 25.0)
	stats.boost_speed = data.get("boost_speed", 37.5)
	stats.friction = data.get("friction", 0.96)
	stats.normal_grip = data.get("normal_grip", 0.15)
	stats.drift_grip = data.get("drift_grip", 0.015)
	stats.turn_speed_normal = data.get("turn_speed_normal", 5.0)
	stats.turn_speed_drift = data.get("turn_speed_drift", 10.0)
	stats.charge_rate = data.get("charge_rate", 30.0)
	stats.max_charge = data.get("max_charge", 100.0)
	stats.boost_duration = data.get("boost_duration", 1.0)
	stats.nitro_max = data.get("nitro_max", 100.0)
	stats.nitro_accumulation_rate = data.get("nitro_accumulation_rate", 10.0)
	stats.nitro_drain_rate = data.get("nitro_drain_rate", 25.0)
	stats.nitro_damage = data.get("nitro_damage", 30.0)
	stats.weapon_slots = int(data.get("weapon_slots", 4))
	return stats
