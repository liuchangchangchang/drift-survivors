class_name LootDrop
extends Area3D
## A material/XP pickup that can be collected by the player.

var value: int = 1
var is_collected: bool = false
var _velocity: Vector3 = Vector3.ZERO
var _friction: float = 5.0

func setup(drop_value: int, spawn_pos: Vector3) -> void:
	value = drop_value
	global_position = spawn_pos
	is_collected = false
	visible = true
	var scatter := Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()
	_velocity = scatter * randf_range(2.5, 7.5)

var _time: float = 0.0

func _physics_process(delta: float) -> void:
	if is_collected:
		return
	# Scatter movement
	if _velocity.length() > 0.05:
		global_position += _velocity * delta
		_velocity = _velocity.lerp(Vector3.ZERO, _friction * delta)
	# Floating bob + spin animation
	_time += delta
	var vis := get_node_or_null("LootVisual")
	if vis:
		vis.position.y = 0.4 + sin(_time * 3.0) * 0.15
		vis.rotation.y += delta * 2.5

func collect() -> void:
	if is_collected:
		return
	is_collected = true
	visible = false
	EventBus.material_collected.emit(value)
	EventBus.xp_gained.emit(value)
