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
	if not is_inside_tree():
		return
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
	var proj := Area2D.new()
	proj.position = Vector2.ZERO
	proj.global_position = global_position
	# Visual
	var visual := ColorRect.new()
	visual.color = Color(1.0, 1.0, 0.3)
	visual.size = Vector2(6, 6)
	visual.position = Vector2(-3, -3)
	proj.add_child(visual)
	# Collision
	var col := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 4.0
	col.shape = shape
	proj.add_child(col)
	proj.collision_layer = 4  # projectiles layer
	proj.collision_mask = 2   # enemies layer
	# Attach script-like behavior via metadata
	proj.set_meta("direction", direction)
	proj.set_meta("speed", data.projectile_speed)
	proj.set_meta("damage", data.damage * damage_multiplier)
	proj.set_meta("knockback", data.knockback)
	proj.set_meta("piercing", data.piercing)
	proj.set_meta("range_left", data.weapon_range)
	proj.set_meta("damage_type", data.damage_type)
	# Add to scene tree (parent of weapon's parent = car, parent of car = arena)
	var arena := _get_arena()
	if arena:
		arena.add_child(proj)
		proj.global_position = global_position
	else:
		proj.queue_free()
		return
	# Connect overlap
	proj.area_entered.connect(func(area: Area2D): _on_proj_hit(proj, area))
	proj.body_entered.connect(func(body: Node2D): _on_proj_body_hit(proj, body))

func _get_arena() -> Node:
	# Walk up to find the arena (root gameplay node)
	var node: Node = self
	while node:
		if node.name == "GameArena" or node is Node2D and node.get_parent() == get_tree().root:
			return node
		node = node.get_parent()
	return get_tree().current_scene

func _on_proj_hit(proj: Area2D, _area: Area2D) -> void:
	pass

func _on_proj_body_hit(proj: Area2D, body: Node2D) -> void:
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		var dmg: float = proj.get_meta("damage", 0.0)
		var kb: float = proj.get_meta("knockback", 0.0)
		body.take_damage(dmg, kb, proj.global_position)
		EventBus.enemy_damaged.emit(body, dmg, proj.get_meta("damage_type", "ranged"))
		var piercing: int = proj.get_meta("piercing", 0)
		piercing -= 1
		if piercing < 0:
			proj.queue_free()
		else:
			proj.set_meta("piercing", piercing)

func _apply_damage_to(target: Node2D) -> void:
	var final_damage := data.damage * damage_multiplier
	if target.has_method("take_damage"):
		target.take_damage(final_damage, data.knockback, global_position)
		EventBus.enemy_damaged.emit(target, final_damage, data.damage_type)

func get_effective_damage() -> float:
	return data.damage * damage_multiplier
