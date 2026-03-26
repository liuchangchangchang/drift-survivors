class_name LootDrop
extends Area2D
## A material/XP pickup that can be collected by the player.

var value: int = 1
var is_collected: bool = false
var _velocity: Vector2 = Vector2.ZERO
var _friction: float = 5.0

func setup(drop_value: int, spawn_pos: Vector2) -> void:
	value = drop_value
	global_position = spawn_pos
	is_collected = false
	visible = true
	# Random scatter direction
	var scatter := Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	_velocity = scatter * randf_range(50, 150)

func _physics_process(delta: float) -> void:
	if is_collected:
		return
	# Apply scatter velocity with friction
	if _velocity.length() > 1.0:
		global_position += _velocity * delta
		_velocity = _velocity.lerp(Vector2.ZERO, _friction * delta)

func collect() -> void:
	if is_collected:
		return
	is_collected = true
	visible = false
	EventBus.material_collected.emit(value)
	EventBus.xp_gained.emit(value)
