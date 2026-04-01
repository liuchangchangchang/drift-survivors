class_name CarScene
extends Node3D

@export var id: String = ""
@export var car_name: String = ""
@export var unlock_condition: String = "none"

@export_group("Health")
@export var max_hp: float = 100.0
@export var hp_regen: float = 1.0
@export var armor: float = 0.0

@export_group("Movement")
@export var max_speed: float = 28.0
@export var boost_speed: float = 45.0
@export var base_accel: float = 35.0
@export var friction: float = 0.98
@export var normal_grip: float = 0.15
@export var drift_grip: float = 0.02
@export var turn_speed_normal: float = 8.0
@export var turn_speed_drift: float = 12.0

@export_group("Drift Charge")
@export var charge_rate: float = 50.0
@export var max_charge: float = 100.0
@export var boost_duration: float = 1.5

@export_group("Nitro")
@export var nitro_max: float = 100.0
@export var nitro_accumulation_rate: float = 10.0
@export var nitro_drain_rate: float = 25.0
@export var nitro_damage: float = 30.0

@export_group("Equipment")
@export var weapon_slots: int = 4

@export_group("Animation")
@export var roll_normal: float = 0.15
@export var roll_drift: float = 0.30
@export var roll_lerp_speed: float = 8.0
@export var pitch_accel: float = -0.025
@export var pitch_boost: float = -0.06
@export var pitch_idle: float = 0.015
@export var pitch_lerp_speed: float = 6.0

func to_stats_dict() -> Dictionary:
	return {
		"max_hp": max_hp,
		"hp_regen": hp_regen,
		"armor": armor,
		"max_speed": max_speed,
		"boost_speed": boost_speed,
		"base_accel": base_accel,
		"friction": friction,
		"normal_grip": normal_grip,
		"drift_grip": drift_grip,
		"turn_speed_normal": turn_speed_normal,
		"turn_speed_drift": turn_speed_drift,
		"charge_rate": charge_rate,
		"max_charge": max_charge,
		"boost_duration": boost_duration,
		"nitro_max": nitro_max,
		"nitro_accumulation_rate": nitro_accumulation_rate,
		"nitro_drain_rate": nitro_drain_rate,
		"nitro_damage": nitro_damage,
		"weapon_slots": weapon_slots,
		"roll_normal": roll_normal,
		"roll_drift": roll_drift,
		"roll_lerp_speed": roll_lerp_speed,
		"pitch_accel": pitch_accel,
		"pitch_boost": pitch_boost,
		"pitch_idle": pitch_idle,
		"pitch_lerp_speed": pitch_lerp_speed,
	}

func to_data_dict() -> Dictionary:
	return {
		"id": id,
		"name": car_name,
		"base_stats": to_stats_dict(),
		"unlock_condition": unlock_condition,
	}
