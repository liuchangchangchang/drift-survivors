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
	# Visual: glowing diamond crystal
	var vis_root := Node3D.new()
	vis_root.name = "LootVisual"
	# Diamond shape (rotated box)
	var crystal := MeshInstance3D.new()
	var crystal_mesh := BoxMesh.new()
	crystal_mesh.size = Vector3(0.3, 0.5, 0.3)
	crystal.mesh = crystal_mesh
	crystal.rotation_degrees = Vector3(0, 45, 0)
	crystal.position = Vector3(0, 0.4, 0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.1, 0.95, 0.4)
	mat.emission_enabled = true
	mat.emission = Color(0.1, 0.95, 0.4)
	mat.emission_energy_multiplier = 3.0
	mat.metallic = 0.8
	mat.roughness = 0.1
	crystal.material_override = mat
	vis_root.add_child(crystal)
	# Point light for glow
	var glow := OmniLight3D.new()
	glow.light_color = Color(0.2, 1.0, 0.4)
	glow.light_energy = 0.5
	glow.omni_range = 2.0
	glow.position = Vector3(0, 0.5, 0)
	vis_root.add_child(glow)
	drop.add_child(vis_root)
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
