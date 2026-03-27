class_name LootSpawner
extends Node
## Spawns loot drops when enemies die.

const MAX_DROPS_ON_MAP := 50

var active_drops: Array[LootDrop] = []

func _ready() -> void:
	EventBus.enemy_killed.connect(_on_enemy_killed)

func _on_enemy_killed(_enemy: Node3D, pos: Vector3, material_value: int) -> void:
	spawn_drop(pos, material_value)

func spawn_drop(pos: Vector3, value: int) -> LootDrop:
	if active_drops.size() >= MAX_DROPS_ON_MAP:
		_merge_into_nearest(pos, value)
		return null

	var drop := LootDrop.new()
	drop.collision_layer = 16  # Layer 5 (loot)
	drop.collision_mask = 0
	var collision := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.5
	collision.shape = shape
	drop.add_child(collision)
	# Visual: small green box
	var visual := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.4, 0.4, 0.4)
	visual.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.9, 0.3)
	mat.emission_enabled = true
	mat.emission = Color(0.2, 0.9, 0.3)
	mat.emission_energy_multiplier = 1.5
	visual.material_override = mat
	drop.add_child(visual)
	drop.add_to_group("loot")
	add_child(drop)
	drop.setup(value, pos)
	active_drops.append(drop)
	return drop

func collect_drop(drop: LootDrop) -> void:
	if drop in active_drops:
		drop.collect()
		active_drops.erase(drop)
		drop.queue_free()

func _merge_into_nearest(pos: Vector3, value: int) -> void:
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
