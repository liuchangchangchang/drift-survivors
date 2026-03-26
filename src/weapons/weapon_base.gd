class_name WeaponBase
extends Node2D
## Base weapon that auto-fires at the nearest enemy within range.

var data: WeaponData
var cooldown_timer: float = 0.0
var damage_multiplier: float = 1.0
var fire_rate_multiplier: float = 1.0

func setup(weapon_data: WeaponData) -> void:
	data = weapon_data

func _physics_process(delta: float) -> void:
	if data == null:
		return
	cooldown_timer -= delta
	if cooldown_timer <= 0.0:
		_try_fire()

func _try_fire() -> void:
	var target := TargetingSystem.find_nearest_enemy(
		global_position, data.weapon_range, get_tree()
	)
	if target == null:
		return
	var direction := global_position.direction_to(target.global_position)
	fire(direction)

func fire(direction: Vector2) -> void:
	var effective_rate := data.fire_rate / maxf(0.1, fire_rate_multiplier)
	cooldown_timer = effective_rate

	if data.type == "melee":
		_fire_melee(direction)
	else:
		_fire_ranged(direction)

	EventBus.weapon_fired.emit(data.id)

func _fire_ranged(direction: Vector2) -> void:
	for i in data.projectile_count:
		var spread := 0.0
		if data.projectile_count > 1 and data.spread_angle > 0:
			# Distribute projectiles evenly across spread
			var spread_rad := deg_to_rad(data.spread_angle)
			spread = -spread_rad / 2.0 + spread_rad * (float(i) / float(data.projectile_count - 1))
		var proj_dir := direction.rotated(spread)
		_spawn_projectile(proj_dir)

func _fire_melee(direction: Vector2) -> void:
	# Melee: damage all enemies in an arc
	var targets := TargetingSystem.find_enemies_in_range(
		global_position, data.weapon_range, get_tree()
	)
	var arc_rad := deg_to_rad(data.spread_angle)
	for target in targets:
		var to_target := global_position.direction_to(target.global_position)
		var angle := direction.angle_to(to_target)
		if absf(angle) <= arc_rad / 2.0:
			_apply_damage_to(target)

func _spawn_projectile(direction: Vector2) -> void:
	# Projectile spawning will be handled by the weapon mount manager
	# For now, emit a signal or create a basic projectile
	pass

func _apply_damage_to(target: Node2D) -> void:
	var final_damage := data.damage * damage_multiplier
	if target.has_method("take_damage"):
		target.take_damage(final_damage, data.knockback, global_position)
		EventBus.enemy_damaged.emit(target, final_damage, data.damage_type)

func get_effective_damage() -> float:
	return data.damage * damage_multiplier
