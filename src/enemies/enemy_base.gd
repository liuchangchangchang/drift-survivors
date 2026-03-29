class_name EnemyBase
extends CharacterBody3D
## Base enemy that chases the player and deals contact damage.

var data: EnemyData
var current_hp: float = 20.0
var is_alive: bool = true
var target: Node3D = null

func setup(enemy_data: EnemyData) -> void:
	data = enemy_data
	current_hp = data.max_hp
	is_alive = true

func _physics_process(delta: float) -> void:
	if not is_alive or target == null:
		return
	_move_toward_target(delta)
	move_and_slide()

func _move_toward_target(_delta: float) -> void:
	var direction := global_position.direction_to(target.global_position)
	direction.y = 0
	if direction.length_squared() > 0.001:
		direction = direction.normalized()
	velocity = direction * data.speed

func take_damage(amount: float, knockback_force: float = 0.0, source_pos: Vector3 = Vector3.ZERO) -> void:
	if not is_alive:
		return
	current_hp -= amount
	if knockback_force > 0.0 and source_pos != Vector3.ZERO:
		var kb_dir := source_pos.direction_to(global_position)
		kb_dir.y = 0
		velocity += kb_dir.normalized() * knockback_force
	if current_hp <= 0.0:
		current_hp = 0.0
		die()

func die() -> void:
	if not is_alive:
		return
	is_alive = false
	var death_pos := global_position if is_inside_tree() else Vector3.ZERO
	_spawn_death_effect()
	EventBus.enemy_killed.emit(self, death_pos, data.material_drop)

func _spawn_death_effect() -> void:
	if not is_inside_tree():
		return
	var particles := GPUParticles3D.new()
	particles.emitting = true
	particles.one_shot = true
	particles.amount = 16
	particles.lifetime = 0.6
	particles.explosiveness = 0.95
	particles.visibility_aabb = AABB(Vector3(-4, -2, -4), Vector3(8, 5, 8))
	var pmat := ParticleProcessMaterial.new()
	pmat.direction = Vector3(0, 1, 0)
	pmat.spread = 180.0
	pmat.initial_velocity_min = 4.0
	pmat.initial_velocity_max = 8.0
	pmat.gravity = Vector3(0, -5, 0)
	pmat.scale_min = 0.2
	pmat.scale_max = 0.6
	pmat.damping_min = 2.0
	pmat.damping_max = 4.0
	# Color from enemy type
	var body_color := Color(0.9, 0.2, 0.2)
	if data:
		match data.type:
			"elite": body_color = Color(0.8, 0.5, 0.1)
			"boss": body_color = Color(0.6, 0.1, 0.6)
	pmat.color = body_color
	particles.process_material = pmat
	var draw_mat := StandardMaterial3D.new()
	draw_mat.albedo_color = Color(body_color.r, body_color.g, body_color.b, 0.8)
	draw_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	draw_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	draw_mat.emission_enabled = true
	draw_mat.emission = body_color
	draw_mat.emission_energy_multiplier = 2.0
	var draw_mesh := QuadMesh.new()
	draw_mesh.size = Vector2(0.4, 0.4)
	draw_mesh.material = draw_mat
	particles.draw_pass_1 = draw_mesh
	# Add to arena first, then set position
	var arena := get_tree().current_scene
	if arena:
		arena.add_child(particles)
		particles.global_position = global_position + Vector3(0, 0.5, 0)
		var timer := arena.get_tree().create_timer(1.5)
		timer.timeout.connect(func(): if is_instance_valid(particles): particles.queue_free())

func get_contact_damage() -> float:
	if data:
		return data.contact_damage
	return 0.0

func reset_for_pool() -> void:
	current_hp = 0.0
	is_alive = false
	velocity = Vector3.ZERO
	target = null
	visible = false
	set_process(false)
	set_physics_process(false)

func activate(enemy_data: EnemyData, spawn_pos: Vector3, player: Node3D) -> void:
	setup(enemy_data)
	global_position = spawn_pos
	target = player
	visible = true
	set_process(true)
	set_physics_process(true)
