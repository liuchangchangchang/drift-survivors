extends Control
## Main menu screen.

func _ready() -> void:
	$VBoxContainer/StartButton.pressed.connect(_on_start)
	$VBoxContainer/QuitButton.pressed.connect(_on_quit)

func _on_start() -> void:
	GameManager.start_new_run()

func _on_quit() -> void:
	get_tree().quit()
