class_name LootDrop
extends Area3D
## A material/XP pickup that can be collected by the player.

var value: int = 1
var is_collected: bool = false
var is_attracted: bool = false
var _attract_target: Node3D = null
var _attract_speed: float = 0.0
var _velocity: Vector3 = Vector3.ZERO
var _friction: float = 5.0
var _time: float = 0.0

func setup(drop_value: int, spawn_pos: Vector3) -> void:
	value = drop_value
	global_position = spawn_pos
	is_collected = false
	is_attracted = false
	_attract_target = null
	visible = true
	var scatter := Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()
	_velocity = scatter * randf_range(2.5, 7.5)

func _physics_process(delta: float) -> void:
	if is_collected:
		return
	# Attraction mode: fly toward player
	if is_attracted and _attract_target and is_instance_valid(_attract_target):
		_attract_speed = minf(_attract_speed + 60.0 * delta, 40.0)
		var dir := global_position.direction_to(_attract_target.global_position)
		dir.y = 0
		global_position += dir * _attract_speed * delta
		# Check arrival
		if global_position.distance_to(_attract_target.global_position) < 1.0:
			_do_collect()
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

## Called by LootMagnet when in range - starts attraction
func start_attract(target: Node3D) -> void:
	if is_collected or is_attracted:
		return
	is_attracted = true
	_attract_target = target
	_attract_speed = 5.0

## Legacy immediate collect (for wave-end auto-collect)
func collect() -> void:
	_do_collect()

func _do_collect() -> void:
	if is_collected:
		return
	is_collected = true
	visible = false
	EventBus.material_collected.emit(value)
	EventBus.xp_gained.emit(value)
