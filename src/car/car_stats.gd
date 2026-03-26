class_name CarStats
extends Resource
## Holds base stats for a car. Loaded from JSON data.

@export var max_hp: float = 100.0
@export var hp_regen: float = 1.0
@export var max_speed: float = 500.0
@export var boost_speed: float = 750.0
@export var engine_power: float = 400.0
@export var steer_angle: float = 15.0
@export var traction_normal: float = 0.75
@export var traction_drift: float = 0.05
@export var slip_speed: float = 300.0
@export var nitro_max: float = 100.0
@export var nitro_accumulation_rate: float = 10.0
@export var nitro_drain_rate: float = 25.0
@export var nitro_damage: float = 30.0
@export var armor: float = 0.0
@export var weapon_slots: int = 4

static func from_dict(data: Dictionary) -> CarStats:
	var stats := CarStats.new()
	stats.max_hp = data.get("max_hp", 100.0)
	stats.hp_regen = data.get("hp_regen", 1.0)
	stats.max_speed = data.get("max_speed", 500.0)
	stats.boost_speed = data.get("boost_speed", 750.0)
	stats.engine_power = data.get("engine_power", 400.0)
	stats.steer_angle = data.get("steer_angle", 15.0)
	stats.traction_normal = data.get("traction_normal", 0.75)
	stats.traction_drift = data.get("traction_drift", 0.05)
	stats.slip_speed = data.get("slip_speed", 300.0)
	stats.nitro_max = data.get("nitro_max", 100.0)
	stats.nitro_accumulation_rate = data.get("nitro_accumulation_rate", 10.0)
	stats.nitro_drain_rate = data.get("nitro_drain_rate", 25.0)
	stats.nitro_damage = data.get("nitro_damage", 30.0)
	stats.armor = data.get("armor", 0.0)
	stats.weapon_slots = int(data.get("weapon_slots", 4))
	return stats
