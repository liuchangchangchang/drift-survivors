extends Control
## Main menu screen.

func _ready() -> void:
	$VBoxContainer/StartButton.pressed.connect(_on_start)
	$VBoxContainer/SettingsButton.pressed.connect(_on_settings)
	$VBoxContainer/QuitButton.pressed.connect(_on_quit)

func _on_start() -> void:
	GameManager.start_new_run()

func _on_settings() -> void:
	var settings_scene: Resource = load("res://scenes/ui/settings.tscn")
	if settings_scene:
		var settings_node: Control = settings_scene.instantiate()
		settings_node.set("_return_scene", "res://scenes/ui/main_menu.tscn")
		get_tree().root.add_child(settings_node)
		visible = false
		settings_node.connect("settings_closed", func(): visible = true; settings_node.queue_free())

func _on_quit() -> void:
	get_tree().quit()
