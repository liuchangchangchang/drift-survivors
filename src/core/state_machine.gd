class_name StateMachine
extends Node
## Generic finite state machine. Children should be State nodes.

@export var initial_state: State

var current_state: State
var states: Dictionary = {}

func _ready() -> void:
	for child in get_children():
		if child is State:
			states[child.name.to_lower()] = child
			child.transitioned.connect(_on_state_transitioned)
	if initial_state:
		initial_state.enter({})
		current_state = initial_state

func _process(delta: float) -> void:
	if current_state:
		current_state.update(delta)

func _physics_process(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)

func _unhandled_input(event: InputEvent) -> void:
	if current_state:
		current_state.handle_input(event)

func transition_to(state_name: String, args: Dictionary = {}) -> void:
	var new_state: State = states.get(state_name.to_lower())
	if new_state == null:
		push_warning("StateMachine: State '%s' not found" % state_name)
		return
	if new_state == current_state:
		return
	if current_state:
		current_state.exit()
	args["previous_state"] = current_state.name if current_state else ""
	new_state.enter(args)
	current_state = new_state

func _on_state_transitioned(state: State, new_state_name: String) -> void:
	if state != current_state:
		return
	transition_to(new_state_name)

func get_state(state_name: String) -> State:
	return states.get(state_name.to_lower())
