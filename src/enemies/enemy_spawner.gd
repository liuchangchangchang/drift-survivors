class_name EnemySpawner
extends Node
## Spawns enemies off-screen around the player.

const SPAWN_MARGIN := 100.0  # Pixels beyond screen edge

var active_enemies: Array[EnemyBase] = []
var max_enemies: int = 100
var player: Node2D = null
var viewport_size: Vector2 = Vector2(1920, 1080)

signal enemy_spawned(enemy: EnemyBase)

## Spawn an enemy with the given data at a random off-screen position
func spawn_enemy(data: EnemyData) -> EnemyBase:
	if active_enemies.size() >= max_enemies:
		return null
	if player == null:
		return null
	var enemy := EnemyBase.new()
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = _get_radius_for_size(data.size)
	collision.shape = shape
	enemy.add_child(collision)
	enemy.add_to_group("enemies")
	var spawn_pos := _get_spawn_position()
	enemy.activate(data, spawn_pos, player)
	active_enemies.append(enemy)
	add_child(enemy)
	enemy_spawned.emit(enemy)
	EventBus.enemy_spawned.emit(enemy)
	return enemy

## Remove a dead enemy from tracking
func on_enemy_killed(enemy: Node2D, _pos: Vector2, _value: int) -> void:
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

func _get_spawn_position() -> Vector2:
	if player == null:
		return Vector2.ZERO
	var half_w := viewport_size.x / 2.0 + SPAWN_MARGIN
	var half_h := viewport_size.y / 2.0 + SPAWN_MARGIN
	var side := randi() % 4
	var pos := player.global_position
	match side:
		0: # Top
			pos += Vector2(randf_range(-half_w, half_w), -half_h)
		1: # Bottom
			pos += Vector2(randf_range(-half_w, half_w), half_h)
		2: # Left
			pos += Vector2(-half_w, randf_range(-half_h, half_h))
		3: # Right
			pos += Vector2(half_w, randf_range(-half_h, half_h))
	return pos

func _get_radius_for_size(size_name: String) -> float:
	match size_name:
		"tiny": return 8.0
		"small": return 12.0
		"medium": return 20.0
		"large": return 30.0
		"boss": return 50.0
	return 12.0
