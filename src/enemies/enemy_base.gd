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
	EventBus.enemy_killed.emit(self, global_position, data.material_drop)

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
