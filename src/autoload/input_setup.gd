extends Node
## Sets up gamepad input mappings at runtime.

func _ready() -> void:
	_add_joy_mapping()

func _add_joy_mapping() -> void:
	# Left stick for movement
	_add_joy_axis("move_left", JOY_AXIS_LEFT_X, -1.0)
	_add_joy_axis("move_right", JOY_AXIS_LEFT_X, 1.0)
	_add_joy_axis("move_up", JOY_AXIS_LEFT_Y, -1.0)
	_add_joy_axis("move_down", JOY_AXIS_LEFT_Y, 1.0)
	# A button = drift (Xbox A / PS X)
	_add_joy_button("drift", JOY_BUTTON_A)
	# B button = nitro (Xbox B / PS Circle)
	_add_joy_button("nitro_boost", JOY_BUTTON_B)
	# Start = pause
	_add_joy_button("pause", JOY_BUTTON_START)
	# Y button = level up open (Xbox Y / PS Triangle)
	_add_joy_button("level_up_open", JOY_BUTTON_Y)
	# Right trigger = drift alternative
	_add_joy_axis("drift", JOY_AXIS_TRIGGER_RIGHT, 1.0)
	# Left trigger = nitro alternative
	_add_joy_axis("nitro_boost", JOY_AXIS_TRIGGER_LEFT, 1.0)

func _add_joy_button(action: String, button: int) -> void:
	if not InputMap.has_action(action):
		return
	var ev := InputEventJoypadButton.new()
	ev.button_index = button
	InputMap.action_add_event(action, ev)

func _add_joy_axis(action: String, axis: int, value: float) -> void:
	if not InputMap.has_action(action):
		return
	var ev := InputEventJoypadMotion.new()
	ev.axis = axis
	ev.axis_value = value
	InputMap.action_add_event(action, ev)
