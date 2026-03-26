extends Control
## Pause menu overlay.

func _ready() -> void:
	visible = false
	$Panel/VBoxContainer/ResumeButton.pressed.connect(_on_resume)
	$Panel/VBoxContainer/QuitButton.pressed.connect(_on_quit)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if visible:
			_on_resume()
		elif GameManager.current_state == GameManager.GameState.PLAYING:
			_show_pause()
		get_viewport().set_input_as_handled()

func _show_pause() -> void:
	visible = true
	get_tree().paused = true
	GameManager.pause_game()

func _on_resume() -> void:
	visible = false
	get_tree().paused = false
	GameManager.resume_game()

func _on_quit() -> void:
	get_tree().paused = false
	GameManager.return_to_menu()
