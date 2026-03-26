extends Control
## Victory screen after completing all 20 waves.

@onready var menu_button: Button = $Panel/VBoxContainer/MenuButton

func _ready() -> void:
	visible = false
	if menu_button:
		menu_button.pressed.connect(_on_menu)

func show_victory() -> void:
	visible = true

func _on_menu() -> void:
	visible = false
	GameManager.return_to_menu()
