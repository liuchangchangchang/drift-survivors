class_name SkidmarkSystem
extends Node3D
## Draws tire skidmarks on the ground during drift.
## Spawns dark quads at rear wheel world positions.

const MAX_MARKS := 600
const MARK_INTERVAL := 0.03  # Seconds between marks
const MARK_WIDTH := 0.18
const MARK_LENGTH := 0.5
const MARK_Y := 0.015

var _timer: float = 0.0
var _mark_count: int = 0
var _marks_container: Node3D
var _mark_material: StandardMaterial3D

func _ready() -> void:
	_marks_container = Node3D.new()
	_marks_container.name = "SkidMarks"
	call_deferred("_add_container_to_arena")

	_mark_material = StandardMaterial3D.new()
	_mark_material.albedo_color = Color(0.02, 0.02, 0.02, 0.8)
	_mark_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mark_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

func _add_container_to_arena() -> void:
	var node: Node = get_parent()
	while node:
		if node.name == "GameArena":
			node.add_child(_marks_container)
			return
		node = node.get_parent()
	if is_inside_tree():
		get_tree().current_scene.add_child(_marks_container)

func _physics_process(delta: float) -> void:
	var car := get_parent() as CarController
	if not car or not car.is_alive or not car.is_drifting:
		return
	if car.velocity.length() < 2.0:
		return

	_timer += delta
	if _timer < MARK_INTERVAL:
		return
	_timer = 0.0

	# Get rear wheel positions from the Visuals node
	var visuals := car.get_node_or_null("Visuals")
	if not visuals:
		return

	# Rear wheels are Wheel_2 (RL) and Wheel_3 (RR) in Visuals
	var rl := visuals.get_node_or_null("Wheel_2")
	var rr := visuals.get_node_or_null("Wheel_3")
	if not rl or not rr:
		return

	var yaw: float = visuals.rotation.y
	_spawn_mark(rl.global_position, yaw)
	_spawn_mark(rr.global_position, yaw)

func _spawn_mark(world_pos: Vector3, yaw: float) -> void:
	if _mark_count >= MAX_MARKS:
		var oldest := _marks_container.get_child(0)
		oldest.global_position = Vector3(world_pos.x, MARK_Y, world_pos.z)
		oldest.rotation.y = yaw
		_marks_container.move_child(oldest, _marks_container.get_child_count() - 1)
		return

	var mark := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(MARK_WIDTH, MARK_LENGTH)
	quad.orientation = PlaneMesh.FACE_Y
	mark.mesh = quad
	mark.material_override = _mark_material
	mark.global_position = Vector3(world_pos.x, MARK_Y, world_pos.z)
	mark.rotation.y = yaw
	_marks_container.add_child(mark)
	_mark_count += 1
