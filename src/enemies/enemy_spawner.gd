class_name EnemySpawner
extends Node
## Spawns enemies around the player at a fixed distance.

const SPAWN_DISTANCE := 50.0  # Units from player

var active_enemies: Array[EnemyBase] = []
var max_enemies: int = 100
var player: Node3D = null

signal enemy_spawned(enemy: EnemyBase)

func spawn_enemy(data: EnemyData) -> EnemyBase:
	if active_enemies.size() >= max_enemies:
		return null
	if player == null:
		return null
	var enemy := EnemyBase.new()
	enemy.motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	var collision := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	var radius := _get_radius_for_size(data.size)
	shape.radius = radius
	collision.shape = shape
	enemy.add_child(collision)
	# Visual: sphere mesh
	var visual := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2
	visual.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = _get_color_for_type(data.type)
	visual.material_override = mat
	enemy.add_child(visual)
	enemy.add_to_group("enemies")
	add_child(enemy)
	var spawn_pos := _get_spawn_position()
	enemy.activate(data, spawn_pos, player)
	active_enemies.append(enemy)
	enemy_spawned.emit(enemy)
	EventBus.enemy_spawned.emit(enemy)
	return enemy

func on_enemy_killed(enemy: Node3D, _pos: Vector3, _value: int) -> void:
	if enemy is EnemyBase and enemy in active_enemies:
		active_enemies.erase(enemy)
		enemy.queue_free()

func get_active_count() -> int:
	return active_enemies.size()

func clear_all() -> void:
	for enemy in active_enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	active_enemies.clear()

func _get_spawn_position() -> Vector3:
	if player == null:
		return Vector3.ZERO
	var angle := randf() * TAU
	var dist := SPAWN_DISTANCE + randf_range(0, 10)
	return player.global_position + Vector3(cos(angle) * dist, 0, sin(angle) * dist)

func _get_radius_for_size(size_name: String) -> float:
	match size_name:
		"tiny": return 0.4
		"small": return 0.6
		"medium": return 1.0
		"large": return 1.5
		"boss": return 2.5
	return 0.6

func _get_color_for_type(type: String) -> Color:
	match type:
		"regular": return Color(0.9, 0.2, 0.2)
		"elite": return Color(0.8, 0.5, 0.1)
		"boss": return Color(0.6, 0.1, 0.6)
	return Color(0.9, 0.2, 0.2)
