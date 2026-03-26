class_name State
extends Node
## Base state class for use with StateMachine.

signal transitioned(state: State, new_state_name: String)

func enter(_args: Dictionary) -> void:
	pass

func exit() -> void:
	pass

func update(_delta: float) -> void:
	pass

func physics_update(_delta: float) -> void:
	pass

func handle_input(_event: InputEvent) -> void:
	pass
