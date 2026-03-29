class_name WeaponBase
extends Node3D
## Base weapon that auto-fires at the nearest enemy within range.

var data: WeaponData
var cooldown_timer: float = 0.0
var damage_multiplier: float = 1.0
var fire_rate_multiplier: float = 1.0
var _visual: Node3D = null
var _current_target: Node3D = null

# Weapon visual colors by type
const WEAPON_VISUAL_COLORS := {
	"weapon_pistol": Color(0.7, 0.7, 0.75),
	"weapon_shotgun": Color(0.8, 0.5, 0.2),
	"weapon_smg": Color(0.3, 0.7, 0.3),
	"weapon_sniper": Color(0.4, 0.4, 0.6),
	"weapon_bumper": Color(0.9, 0.2, 0.2),
	"weapon_laser": Color(0.2, 0.6, 1.0),
}

func setup(weapon_data: WeaponData) -> void:
	data = weapon_data
	_build_visual()

func _physics_process(delta: float) -> void:
	if data == null:
		return
	cooldown_timer -= delta
	if cooldown_timer <= 0.0:
		_try_fire()
	# Rotate visual toward current target
	if _visual and _current_target and is_instance_valid(_current_target):
		var dir_to := global_position.direction_to(_current_target.global_position)
		dir_to.y = 0
		if dir_to.length_squared() > 0.001:
			var target_yaw := atan2(dir_to.x, dir_to.z)
			_visual.rotation.y = lerp_angle(_visual.rotation.y, target_yaw, 12.0 * delta)

func _try_fire() -> void:
	if not is_inside_tree():
		return
	var target := TargetingSystem.find_nearest_enemy(
		global_position, data.weapon_range, get_tree()
	)
	_current_target = target
	if target == null:
		return
	var direction := global_position.direction_to(target.global_position)
	direction.y = 0
	if direction.length_squared() > 0.001:
		direction = direction.normalized()
	fire(direction)

func fire(direction: Vector3) -> void:
	var effective_rate := data.fire_rate / maxf(0.1, fire_rate_multiplier)
	cooldown_timer = effective_rate

	if data.type == "melee":
		_fire_melee(direction)
	else:
		_fire_ranged(direction)

	EventBus.weapon_fired.emit(data.id)

func _fire_ranged(direction: Vector3) -> void:
	for i in data.projectile_count:
		var spread := 0.0
		if data.projectile_count > 1 and data.spread_angle > 0:
			var spread_rad := deg_to_rad(data.spread_angle)
			spread = -spread_rad / 2.0 + spread_rad * (float(i) / float(data.projectile_count - 1))
		var proj_dir := direction.rotated(Vector3.UP, spread)
		_spawn_projectile(proj_dir)

func _fire_melee(direction: Vector3) -> void:
	var targets := TargetingSystem.find_enemies_in_range(
		global_position, data.weapon_range, get_tree()
	)
	var arc_rad := deg_to_rad(data.spread_angle)
	for target in targets:
		var to_target := global_position.direction_to(target.global_position)
		to_target.y = 0
		var angle := direction.angle_to(to_target)
		if absf(angle) <= arc_rad / 2.0:
			_apply_damage_to(target)

func _spawn_projectile(direction: Vector3) -> void:
	var proj := Area3D.new()
	# Collision
	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.2
	col.shape = shape
	proj.add_child(col)
	# Visual: small box
	var visual := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.3, 0.3, 0.3)
	visual.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 1.0, 0.3)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 1.0, 0.3)
	mat.emission_energy_multiplier = 2.0
	visual.material_override = mat
	proj.add_child(visual)
	proj.collision_layer = 4  # projectiles
	proj.collision_mask = 2   # enemies
	# Metadata for movement
	proj.set_meta("direction", direction)
	proj.set_meta("speed", data.projectile_speed)
	proj.set_meta("damage", data.damage * damage_multiplier)
	proj.set_meta("knockback", data.knockback)
	proj.set_meta("piercing", data.piercing)
	proj.set_meta("range_left", data.weapon_range)
	proj.set_meta("damage_type", data.damage_type)
	# Add to arena
	var arena := _get_arena()
	if arena:
		arena.add_child(proj)
		proj.global_position = global_position
		proj.global_position.y = 0.5
	else:
		proj.queue_free()
		return
	proj.body_entered.connect(func(body: Node3D): _on_proj_body_hit(proj, body))

func _get_arena() -> Node:
	var node: Node = self
	while node:
		if node.name == "GameArena" or node is Node3D and node.get_parent() == get_tree().root:
			return node
		node = node.get_parent()
	return get_tree().current_scene

func _on_proj_body_hit(proj: Area3D, body: Node3D) -> void:
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

func _apply_damage_to(target: Node3D) -> void:
	var final_damage := data.damage * damage_multiplier
	if target.has_method("take_damage"):
		target.take_damage(final_damage, data.knockback, global_position)
		EventBus.enemy_damaged.emit(target, final_damage, data.damage_type)

func get_effective_damage() -> float:
	return data.damage * damage_multiplier

func _build_visual() -> void:
	if _visual:
		_visual.queue_free()
	if data == null:
		return
	_visual = Node3D.new()
	_visual.name = "WeaponVisual"
	var color: Color = WEAPON_VISUAL_COLORS.get(data.id, Color(0.5, 0.5, 0.6))
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = 0.7
	mat.roughness = 0.25
	if data.type == "melee":
		_build_melee_visual(mat)
	else:
		_build_ranged_visual(mat)
	add_child(_visual)

func _build_ranged_visual(mat: StandardMaterial3D) -> void:
	# Barrel (points -Z = forward)
	var barrel := MeshInstance3D.new()
	var barrel_mesh := CylinderMesh.new()
	barrel_mesh.top_radius = 0.06
	barrel_mesh.bottom_radius = 0.08
	barrel_mesh.height = 0.7
	barrel.mesh = barrel_mesh
	barrel.rotation_degrees = Vector3(90, 0, 0)
	barrel.position = Vector3(0, 0.12, -0.35)
	barrel.material_override = mat
	_visual.add_child(barrel)
	# Body
	var body := MeshInstance3D.new()
	var body_mesh := BoxMesh.new()
	body_mesh.size = Vector3(0.18, 0.16, 0.3)
	body.mesh = body_mesh
	body.position = Vector3(0, 0.12, 0.08)
	body.material_override = mat
	_visual.add_child(body)
	# Muzzle flash point
	var muzzle := MeshInstance3D.new()
	var muzzle_mesh := SphereMesh.new()
	muzzle_mesh.radius = 0.05
	muzzle_mesh.height = 0.1
	muzzle.mesh = muzzle_mesh
	muzzle.position = Vector3(0, 0.12, -0.7)
	var muzzle_mat := StandardMaterial3D.new()
	muzzle_mat.albedo_color = Color(1, 0.8, 0.3)
	muzzle_mat.emission_enabled = true
	muzzle_mat.emission = Color(1, 0.6, 0.2)
	muzzle_mat.emission_energy_multiplier = 2.0
	muzzle.material_override = muzzle_mat
	_visual.add_child(muzzle)

func _build_melee_visual(mat: StandardMaterial3D) -> void:
	# Bumper plate
	var plate := MeshInstance3D.new()
	var plate_mesh := BoxMesh.new()
	plate_mesh.size = Vector3(0.7, 0.22, 0.08)
	plate.mesh = plate_mesh
	plate.position = Vector3(0, 0.12, -0.2)
	plate.material_override = mat
	_visual.add_child(plate)
	# Glow edge
	var glow := MeshInstance3D.new()
	var glow_mesh := BoxMesh.new()
	glow_mesh.size = Vector3(0.66, 0.04, 0.04)
	glow.mesh = glow_mesh
	glow.position = Vector3(0, 0.12, -0.25)
	var glow_mat := StandardMaterial3D.new()
	glow_mat.albedo_color = Color(1, 0.3, 0.1)
	glow_mat.emission_enabled = true
	glow_mat.emission = Color(1, 0.3, 0.1)
	glow_mat.emission_energy_multiplier = 3.0
	glow.material_override = glow_mat
	_visual.add_child(glow)
