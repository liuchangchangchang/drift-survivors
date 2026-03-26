class_name CarController
extends CharacterBody2D
## Main car controller with arcade drift physics.
## Uses velocity lerp with traction values for drift feel.
##
## Key concept: the car always has a "heading" (rotation) and a velocity.
## During normal driving, velocity quickly aligns with heading (high traction).
## During drifting, velocity slowly aligns with heading (low traction), creating slide.

@export var stats: CarStats

# Child components (set in _ready or scene tree)
var drift_sm: DriftStateMachine
var nitro: NitroSystem

# Current state
var current_hp: float = 100.0
var current_speed: float = 0.0
var steer_input: float = 0.0
var is_drifting: bool = false
var is_alive: bool = true

# Physics constants
const FRICTION := -0.9        # Natural deceleration
const DRAG := -0.001          # High-speed drag
const REVERSE_RATIO := 0.4    # Reverse speed = 40% of max
const MIN_SPEED_TO_STEER := 20.0  # Must be moving to steer

func _ready() -> void:
	if stats == null:
		stats = CarStats.new()
	current_hp = stats.max_hp
	# Find or create child components
	drift_sm = _find_or_create_child(DriftStateMachine, "DriftStateMachine")
	nitro = _find_or_create_child(NitroSystem, "NitroSystem")
	nitro.configure(stats)

func _physics_process(delta: float) -> void:
	if not is_alive:
		return
	_handle_input(delta)
	_apply_drift_and_nitro(delta)
	_apply_physics(delta)
	move_and_slide()

func _handle_input(delta: float) -> void:
	steer_input = Input.get_axis("steer_left", "steer_right")
	var accel_input := Input.get_axis("reverse", "accelerate")

	# Acceleration
	if accel_input > 0:
		current_speed += stats.engine_power * accel_input * delta
	elif accel_input < 0:
		current_speed += stats.engine_power * accel_input * REVERSE_RATIO * delta

	# Drift input
	var wants_drift := Input.is_action_pressed("drift")
	var speed_ok := absf(current_speed) > stats.slip_speed
	var steering_ok := absf(steer_input) > 0.1

	if wants_drift and speed_ok and steering_ok and not is_drifting:
		is_drifting = true
		drift_sm.start_drift()
	elif is_drifting and (not wants_drift or not speed_ok):
		_end_drift()

	# Nitro boost input
	if Input.is_action_just_pressed("nitro_boost"):
		nitro.try_activate()

func _apply_drift_and_nitro(delta: float) -> void:
	# Update drift stage
	if is_drifting:
		drift_sm.update_drift(delta)
		var multiplier := drift_sm.get_nitro_multiplier()
		nitro.accumulate(delta, multiplier)

	# Drain nitro if boosting
	if nitro.is_boosting:
		nitro.drain(delta)

func _apply_physics(delta: float) -> void:
	# Steering (only when moving)
	if absf(current_speed) > MIN_SPEED_TO_STEER:
		var steer_amount := steer_input * stats.steer_angle
		# Increase steering responsiveness during drift
		if is_drifting:
			steer_amount *= 1.3
		rotation += deg_to_rad(steer_amount) * delta * (current_speed / stats.max_speed)

	# Apply friction and drag
	if current_speed > 0:
		current_speed += current_speed * FRICTION * delta
		current_speed += current_speed * absf(current_speed) * DRAG * delta
	elif current_speed < 0:
		current_speed -= current_speed * FRICTION * delta

	# Speed cap
	var max_spd := stats.boost_speed if nitro.is_boosting else stats.max_speed
	var min_spd := -stats.max_speed * REVERSE_RATIO
	current_speed = clampf(current_speed, min_spd, max_spd)

	# Calculate desired velocity based on heading
	var heading := Vector2.UP.rotated(rotation)
	var desired_velocity := heading * current_speed

	# Traction interpolation - this is the core of drift feel
	var traction := stats.traction_drift if is_drifting else stats.traction_normal
	velocity = velocity.lerp(desired_velocity, traction)

func _end_drift() -> void:
	var ended_stage := drift_sm.end_drift()
	is_drifting = false
	# Auto-activate nitro on drift release if at READY stage
	if ended_stage == DriftStateMachine.DriftStage.READY:
		nitro.try_activate()

func take_damage(amount: float, source: Node2D = null) -> void:
	if not is_alive:
		return
	var actual_damage := maxf(0.0, amount - stats.armor)
	current_hp -= actual_damage
	EventBus.car_damaged.emit(actual_damage, source)
	if current_hp <= 0.0:
		current_hp = 0.0
		die()

func heal(amount: float) -> void:
	if not is_alive:
		return
	current_hp = minf(current_hp + amount, stats.max_hp)
	EventBus.car_healed.emit(amount)

func die() -> void:
	is_alive = false
	current_hp = 0.0
	current_speed = 0.0
	velocity = Vector2.ZERO
	EventBus.car_died.emit()

func get_hp_normalized() -> float:
	if stats.max_hp <= 0.0:
		return 0.0
	return current_hp / stats.max_hp

func get_speed_normalized() -> float:
	var max_spd := stats.boost_speed if nitro.is_boosting else stats.max_speed
	if max_spd <= 0.0:
		return 0.0
	return absf(current_speed) / max_spd

func _find_or_create_child(type: Variant, node_name: String) -> Node:
	for child in get_children():
		if is_instance_of(child, type):
			return child
	var node = type.new()
	node.name = node_name
	add_child(node)
	return node
