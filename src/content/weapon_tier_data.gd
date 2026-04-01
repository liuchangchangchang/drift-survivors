class_name WeaponTierData
extends Resource

@export var tier: int = 1
@export var damage: float = 10.0
@export var fire_rate: float = 0.5
@export var weapon_range: float = 15.0
@export var projectile_speed: float = 30.0
@export var projectile_count: int = 1
@export var spread_angle: float = 0.0
@export var piercing: int = 0
@export var knockback: float = 0.5

func to_dict() -> Dictionary:
	return {
		"tier": tier,
		"damage": damage,
		"fire_rate": fire_rate,
		"range": weapon_range,
		"projectile_speed": projectile_speed,
		"projectile_count": projectile_count,
		"spread_angle": spread_angle,
		"piercing": piercing,
		"knockback": knockback,
	}
