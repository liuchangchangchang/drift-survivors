class_name CarController
extends CharacterBody3D
## 3D car controller with absolute direction control and arcade drift physics.
##
## Core concept (from 3d.md):
## - WASD maps to world directions (W=-Z, D=+X), NOT relative to car heading
## - visual_angle tracks the car's yaw independently from velocity direction
## - Grip lerps velocity direction toward visual_angle (high grip = responsive, low = drift)
## - Drift release snaps velocity to visual_angle for boost exit

@export var stats: CarStats

# Child components
var drift_sm: DriftStateMachine
var nitro: NitroSystem

# State
var current_hp: float = 100.0
var is_drifting: bool = false
var is_alive: bool = true
var visual_angle: float = 0.0  # Radians, car heading yaw
var drift_charge: float = 0.0
var boost_power: float = 0.0   # Remaining boost time (seconds)

# Speed threshold for drift activation
const DRIFT_SPEED_THRESHOLD := 2.0

func _ready() -> void:
	if stats == null:
		stats = CarStats.new()
	current_hp = stats.max_hp
	motion_mode = MotionMode.MOTION_MODE_FLOATING
	drift_sm = _find_or_create_child(DriftStateMachine, "DriftStateMachine")
	nitro = _find_or_create_child(NitroSystem, "NitroSystem")
	nitro.configure(stats)

func _physics_process(delta: float) -> void:
	if not is_alive:
		return

	# Step 1: Input
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var input_vector := Vector3(input_dir.x, 0, input_dir.y)
	var has_input := input_vector.length_squared() > 0.01

	# Step 2: Drift state
	var current_speed := velocity.length()
	var wants_drift := Input.is_action_pressed("drift")

	if wants_drift and current_speed > DRIFT_SPEED_THRESHOLD and not is_drifting:
		is_drifting = true
		drift_sm.start_drift()
	elif is_drifting and (not wants_drift or current_speed < DRIFT_SPEED_THRESHOLD * 0.5):
		_end_drift()

	# Step 3: Dynamic parameters
	var current_accel := stats.base_accel
	var current_grip := stats.normal_grip
	var current_friction := stats.friction
	var turn_speed := stats.turn_speed_normal

	if boost_power > 0:
		current_accel = stats.base_accel * 2.5
		boost_power -= delta
		if boost_power <= 0:
			boost_power = 0.0
		nitro.drain(delta)
		if is_drifting:
			# Boost + drift: keep drift slip but with boost speed
			current_grip = stats.drift_grip * 1.5
			current_friction = 0.993
			turn_speed = stats.turn_speed_drift
		else:
			current_grip = 0.3
	elif is_drifting:
		current_accel = stats.base_accel * 0.6
		current_grip = stats.drift_grip
		current_friction = 0.992
		turn_speed = stats.turn_speed_drift

	# Step 4: Drift charge (angle diff based, QQ Speed style)
	if is_drifting and current_speed > 1.0:
		drift_sm.update_drift(delta)
		var velocity_angle := atan2(velocity.z, velocity.x)
		var angle_diff := absf(angle_difference(visual_angle, velocity_angle))
		var old_charge := drift_charge
		if angle_diff > 0.05:
			drift_charge += angle_diff * maxf(current_speed, 10.0) * stats.charge_rate * delta
			drift_charge = minf(drift_charge, stats.max_charge)
		else:
			# Even without big angle, slowly charge while drifting
			drift_charge += stats.charge_rate * 0.3 * delta
			drift_charge = minf(drift_charge, stats.max_charge)
		if drift_charge != old_charge:
			EventBus.drift_charge_changed.emit(drift_charge / stats.max_charge)
		# Feed into nitro system with drift stage multiplier
		var stage_mult := drift_sm.get_nitro_multiplier()
		if stage_mult > 0:
			nitro.accumulate(delta, stage_mult * maxf(angle_diff, 0.3))
	elif not is_drifting and boost_power <= 0 and drift_charge > 0:
		drift_charge = maxf(0.0, drift_charge - 40.0 * delta)
		EventBus.drift_charge_changed.emit(drift_charge / stats.max_charge)

	# Step 5: Core kinematics
	# Thrust
	velocity += input_vector * current_accel * delta

	# Visual angle lerp toward input direction
	if has_input:
		var target_angle := atan2(input_vector.z, input_vector.x)
		visual_angle = lerp_angle(visual_angle, target_angle, turn_speed * delta)

	# Grip: lerp velocity direction toward visual_angle
	var post_speed := velocity.length()
	if post_speed > 0.1:
		var post_vel_angle := atan2(velocity.z, velocity.x)
		var new_vel_angle := lerp_angle(post_vel_angle, visual_angle, current_grip)
		velocity = Vector3(cos(new_vel_angle), 0, sin(new_vel_angle)) * post_speed

	# Step 6: Friction and speed cap
	velocity *= current_friction
	var max_spd := stats.boost_speed if boost_power > 0 else stats.max_speed
	if velocity.length() > max_spd:
		velocity = velocity.normalized() * max_spd

	# Step 7: Move
	move_and_slide()

func _input(event: InputEvent) -> void:
	if not is_alive:
		return
	# Drift release -> nitro snap
	if event.is_action_released("drift") and is_drifting:
		_end_drift()

func _end_drift() -> void:
	var ended_stage := drift_sm.end_drift()
	is_drifting = false

	# Snap + boost if enough charge or at READY stage
	var should_boost := drift_charge >= stats.max_charge * 0.5 or ended_stage == DriftStateMachine.DriftStage.READY
	if should_boost and velocity.length() > 0.5:
		# Hard grip snap: velocity aligns to visual_angle
		velocity = Vector3(cos(visual_angle), 0, sin(visual_angle)) * velocity.length()
		boost_power = stats.boost_duration
		nitro.try_activate()

	drift_charge = 0.0
	EventBus.drift_charge_changed.emit(0.0)

func take_damage(amount: float, _knockback: float = 0.0, _source_pos: Vector3 = Vector3.ZERO) -> void:
	if not is_alive:
		return
	var actual_damage := maxf(0.0, amount - stats.armor)
	current_hp -= actual_damage
	EventBus.car_damaged.emit(actual_damage, null)
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
	velocity = Vector3.ZERO
	boost_power = 0.0
	EventBus.car_died.emit()

func get_hp_normalized() -> float:
	if stats.max_hp <= 0.0:
		return 0.0
	return current_hp / stats.max_hp

func get_speed_normalized() -> float:
	var max_spd := stats.boost_speed if boost_power > 0 else stats.max_speed
	if max_spd <= 0.0:
		return 0.0
	return velocity.length() / max_spd

func get_current_speed() -> float:
	return velocity.length()

func _find_or_create_child(type: Variant, node_name: String) -> Node:
	for child in get_children():
		if is_instance_of(child, type):
			return child
	var node = type.new()
	node.name = node_name
	add_child(node)
	return node
