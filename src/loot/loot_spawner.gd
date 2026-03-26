class_name LootSpawner
extends Node
## Spawns loot drops when enemies die.

const MAX_DROPS_ON_MAP := 50

var active_drops: Array[LootDrop] = []

func _ready() -> void:
	EventBus.enemy_killed.connect(_on_enemy_killed)

func _on_enemy_killed(_enemy: Node2D, pos: Vector2, material_value: int) -> void:
	spawn_drop(pos, material_value)

func spawn_drop(pos: Vector2, value: int) -> LootDrop:
	# If at max, merge into existing drops
	if active_drops.size() >= MAX_DROPS_ON_MAP:
		_merge_into_nearest(pos, value)
		return null

	var drop := LootDrop.new()
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 10.0
	collision.shape = shape
	drop.add_child(collision)
	drop.setup(value, pos)
	drop.add_to_group("loot")
	add_child(drop)
	active_drops.append(drop)
	return drop

func collect_drop(drop: LootDrop) -> void:
	if drop in active_drops:
		drop.collect()
		active_drops.erase(drop)
		drop.queue_free()

func _merge_into_nearest(pos: Vector2, value: int) -> void:
	var nearest: LootDrop = null
	var nearest_dist := INF
	for drop in active_drops:
		if not is_instance_valid(drop) or drop.is_collected:
			continue
		var dist := pos.distance_squared_to(drop.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = drop
	if nearest:
		nearest.value += value

func clear_all() -> void:
	for drop in active_drops:
		if is_instance_valid(drop):
			drop.queue_free()
	active_drops.clear()

func get_drop_count() -> int:
	return active_drops.size()
