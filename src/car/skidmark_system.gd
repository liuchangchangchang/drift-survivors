class_name SkidmarkSystem
extends Node3D
## Draws tire skidmarks on the ground during drift.
## Creates flat dark quads behind the rear wheels.

const MAX_MARKS := 500
const MARK_INTERVAL := 0.05  # Seconds between marks
const MARK_WIDTH := 0.15
const MARK_LENGTH := 0.6
const MARK_Y := 0.02  # Slightly above ground to prevent z-fight

var _timer: float = 0.0
var _mark_count: int = 0
var _marks_container: Node3D
var _mark_material: StandardMaterial3D

# Rear wheel offsets relative to car center (local space)
var left_wheel_offset := Vector3(-0.8, 0, 1.2)
var right_wheel_offset := Vector3(0.8, 0, 1.2)

func _ready() -> void:
	_marks_container = Node3D.new()
	_marks_container.name = "SkidMarks"
	# Add to arena (not car) so marks stay in world space
	call_deferred("_add_container_to_arena")

	_mark_material = StandardMaterial3D.new()
	_mark_material.albedo_color = Color(0.05, 0.05, 0.05, 0.7)
	_mark_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mark_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mark_material.no_depth_test = false

func _add_container_to_arena() -> void:
	var arena := _find_arena()
	if arena:
		arena.add_child(_marks_container)
	else:
		get_tree().current_scene.add_child(_marks_container)

func _find_arena() -> Node:
	var node: Node = get_parent()
	while node:
		if node.name == "GameArena":
			return node
		node = node.get_parent()
	return null

func _physics_process(delta: float) -> void:
	var car := get_parent() as CarController
	if not car or not car.is_alive or not car.is_drifting:
		return

	_timer += delta
	if _timer < MARK_INTERVAL:
		return
	_timer = 0.0

	# Get car's visual rotation for wheel positions
	var yaw := -car.visual_angle + PI / 2
	var car_basis := Basis(Vector3.UP, yaw)
	var car_pos := car.global_position

	# Spawn marks at both rear wheels
	_spawn_mark(car_pos + car_basis * left_wheel_offset, yaw)
	_spawn_mark(car_pos + car_basis * right_wheel_offset, yaw)

func _spawn_mark(world_pos: Vector3, yaw: float) -> void:
	if _mark_count >= MAX_MARKS:
		# Recycle oldest mark
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
