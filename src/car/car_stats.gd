class_name CarStats
extends Resource
## Holds base stats for a car. Loaded from JSON data.
## Uses 3D unit-scale values (not pixel-scale).

# Health
@export var max_hp: float = 100.0
@export var hp_regen: float = 1.0
@export var armor: float = 0.0

# Movement (3D absolute direction)
@export var base_accel: float = 35.0
@export var max_speed: float = 28.0
@export var boost_speed: float = 45.0
@export var friction: float = 0.98
@export var normal_grip: float = 0.15
@export var drift_grip: float = 0.02
@export var turn_speed_normal: float = 8.0
@export var turn_speed_drift: float = 12.0

# Drift charge
@export var charge_rate: float = 50.0
@export var max_charge: float = 100.0
@export var boost_duration: float = 1.5

# Nitro
@export var nitro_max: float = 100.0
@export var nitro_accumulation_rate: float = 10.0
@export var nitro_drain_rate: float = 25.0
@export var nitro_damage: float = 30.0

# Equipment
@export var weapon_slots: int = 4

# Animation (body roll & pitch)
@export var roll_normal: float = 0.15
@export var roll_drift: float = 0.30
@export var roll_lerp_speed: float = 8.0
@export var pitch_accel: float = -0.025
@export var pitch_boost: float = -0.06
@export var pitch_idle: float = 0.015
@export var pitch_lerp_speed: float = 6.0

static func from_dict(data: Dictionary) -> CarStats:
	var stats := CarStats.new()
	stats.max_hp = data.get("max_hp", 100.0)
	stats.hp_regen = data.get("hp_regen", 1.0)
	stats.armor = data.get("armor", 0.0)
	stats.base_accel = data.get("base_accel", 35.0)
	stats.max_speed = data.get("max_speed", 28.0)
	stats.boost_speed = data.get("boost_speed", 45.0)
	stats.friction = data.get("friction", 0.98)
	stats.normal_grip = data.get("normal_grip", 0.15)
	stats.drift_grip = data.get("drift_grip", 0.02)
	stats.turn_speed_normal = data.get("turn_speed_normal", 8.0)
	stats.turn_speed_drift = data.get("turn_speed_drift", 12.0)
	stats.charge_rate = data.get("charge_rate", 50.0)
	stats.max_charge = data.get("max_charge", 100.0)
	stats.boost_duration = data.get("boost_duration", 1.5)
	stats.nitro_max = data.get("nitro_max", 100.0)
	stats.nitro_accumulation_rate = data.get("nitro_accumulation_rate", 10.0)
	stats.nitro_drain_rate = data.get("nitro_drain_rate", 25.0)
	stats.nitro_damage = data.get("nitro_damage", 30.0)
	stats.weapon_slots = int(data.get("weapon_slots", 4))
	stats.roll_normal = data.get("roll_normal", 0.15)
	stats.roll_drift = data.get("roll_drift", 0.30)
	stats.roll_lerp_speed = data.get("roll_lerp_speed", 8.0)
	stats.pitch_accel = data.get("pitch_accel", -0.025)
	stats.pitch_boost = data.get("pitch_boost", -0.06)
	stats.pitch_idle = data.get("pitch_idle", 0.015)
	stats.pitch_lerp_speed = data.get("pitch_lerp_speed", 6.0)
	return stats
