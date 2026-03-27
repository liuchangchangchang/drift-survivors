class_name CameraController
extends Camera3D
## Stable top-down chase camera.
## Uses fixed rotation (no look_at jitter) with smooth position follow.

@export var target: Node3D
@export var height: float = 40.0
@export var look_ahead: float = 3.0  # How far ahead of velocity to look
@export var follow_speed: float = 3.0
@export var fast_follow_speed: float = 6.0  # When car moves fast

var _smooth_pos: Vector3 = Vector3.ZERO
var _initialized: bool = false

func _ready() -> void:
	# Fixed top-down angle (slightly tilted for depth perception)
	rotation_degrees = Vector3(-75, 0, 0)

func _physics_process(delta: float) -> void:
	if not target:
		return

	if not _initialized:
		_smooth_pos = target.global_position
		global_position = _smooth_pos + Vector3(0, height, height * 0.27)
		_initialized = true
		return

	# Target position: car pos + look-ahead based on velocity
	var ahead := Vector3.ZERO
	if target is CharacterBody3D and target.velocity.length() > 1.0:
		ahead = target.velocity.normalized() * look_ahead

	var target_focus := target.global_position + ahead

	# Smooth follow with speed-adaptive lerp
	var speed_factor := 1.0
	if target is CharacterBody3D:
		speed_factor = clampf(target.velocity.length() / 20.0, 0.5, 1.5)
	var lerp_rate := lerpf(follow_speed, fast_follow_speed, speed_factor - 0.5) * delta

	_smooth_pos = _smooth_pos.lerp(target_focus, lerp_rate)

	# Camera position: above and slightly behind the focus point
	global_position = _smooth_pos + Vector3(0, height, height * 0.27)
