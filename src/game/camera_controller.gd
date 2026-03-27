class_name CameraController
extends Camera3D
## Top-down chase camera for the 3D arena.
## Follows the player car with lag for speed-feel.

@export var target: Node3D
@export var offset: Vector3 = Vector3(0, 30, 20)
@export var lerp_speed: float = 5.0

func _physics_process(delta: float) -> void:
	if not target:
		return
	var target_pos := target.global_position + offset
	global_position = global_position.lerp(target_pos, lerp_speed * delta)
	# Look slightly ahead of the car
	var look_target := target.global_position
	if target is CharacterBody3D:
		look_target += target.velocity * 0.15
	look_at(look_target, Vector3.UP)
