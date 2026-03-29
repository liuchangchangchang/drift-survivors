extends Control
## Game over screen showing run stats.

@onready var wave_label: Label = $Panel/VBoxContainer/WaveLabel
@onready var retry_button: Button = $Panel/VBoxContainer/RetryButton
@onready var menu_button: Button = $Panel/VBoxContainer/MenuButton

func _ready() -> void:
	visible = false
	if retry_button:
		retry_button.pressed.connect(_on_retry)
	if menu_button:
		menu_button.pressed.connect(_on_menu)

func show_game_over(wave_reached: int) -> void:
	if wave_label:
		wave_label.text = tr("GAMEOVER_WAVE") % wave_reached
	visible = true

func _on_retry() -> void:
	visible = false
	GameManager.start_new_run()

func _on_menu() -> void:
	visible = false
	GameManager.return_to_menu()
