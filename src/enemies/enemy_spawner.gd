class_name EnemySpawner
extends Node
## Spawns enemies around the player at a fixed distance.

const SPAWN_DISTANCE := 50.0  # Units from player
const ARENA_MARGIN := 3.0  # Minimum distance from arena walls

var active_enemies: Array[EnemyBase] = []
var max_enemies: int = 100
var player: Node3D = null
var arena_size: float = 150.0

signal enemy_spawned(enemy: EnemyBase)

func spawn_enemy(data: EnemyData) -> EnemyBase:
	if active_enemies.size() >= max_enemies:
		return null
	if player == null:
		return null
	var enemy := EnemyBase.new()
	enemy.motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	enemy.collision_layer = 2  # enemies layer
	enemy.collision_mask = 1 | 32  # collide with car + arena_boundary
	var collision := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	var radius := _get_radius_for_size(data.size)
	shape.radius = radius
	collision.shape = shape
	enemy.add_child(collision)
	# Visual: body + eyes + glow ring
	var vis_root := Node3D.new()
	vis_root.name = "EnemyVisual"
	# Main body
	var body := MeshInstance3D.new()
	var body_mesh := SphereMesh.new()
	body_mesh.radius = radius
	body_mesh.height = radius * 1.6
	body.mesh = body_mesh
	body.position = Vector3(0, radius * 0.8, 0)
	var body_color := _get_color_for_type(data.type)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = body_color
	mat.metallic = 0.3
	mat.roughness = 0.6
	body.material_override = mat
	vis_root.add_child(body)
	# Eyes (two small white spheres)
	var eye_mat := StandardMaterial3D.new()
	eye_mat.albedo_color = Color(1, 1, 1)
	eye_mat.emission_enabled = true
	eye_mat.emission = Color(1, 1, 0.8)
	eye_mat.emission_energy_multiplier = 2.0
	for eye_x in [-radius * 0.35, radius * 0.35]:
		var eye := MeshInstance3D.new()
		var eye_mesh := SphereMesh.new()
		eye_mesh.radius = radius * 0.15
		eye_mesh.height = radius * 0.3
		eye.mesh = eye_mesh
		eye.position = Vector3(eye_x, radius * 1.0, -radius * 0.7)
		eye.material_override = eye_mat
		vis_root.add_child(eye)
	# Glow ring at base (for elites/bosses)
	if data.type != "regular":
		var ring := MeshInstance3D.new()
		var ring_mesh := TorusMesh.new()
		ring_mesh.inner_radius = radius * 0.8
		ring_mesh.outer_radius = radius * 1.1
		ring.mesh = ring_mesh
		ring.position = Vector3(0, 0.05, 0)
		var ring_mat := StandardMaterial3D.new()
		ring_mat.albedo_color = body_color
		ring_mat.emission_enabled = true
		ring_mat.emission = body_color
		ring_mat.emission_energy_multiplier = 3.0
		ring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		ring_mat.albedo_color.a = 0.6
		ring.material_override = ring_mat
		vis_root.add_child(ring)
	enemy.add_child(vis_root)
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
	var pos := player.global_position + Vector3(cos(angle) * dist, 0, sin(angle) * dist)
	# Clamp to arena bounds
	pos.x = clampf(pos.x, ARENA_MARGIN, arena_size - ARENA_MARGIN)
	pos.z = clampf(pos.z, ARENA_MARGIN, arena_size - ARENA_MARGIN)
	pos.y = 0.0
	return pos

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
