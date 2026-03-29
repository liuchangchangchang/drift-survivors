extends Control
## Photosensitivity/epilepsy warning screen shown on first launch.

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 1)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.offset_left = -350
	vbox.offset_top = -200
	vbox.offset_right = 350
	vbox.offset_bottom = 200
	vbox.add_theme_constant_override("separation", 20)
	add_child(vbox)

	var icon := Label.new()
	icon.text = "WARNING"
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.add_theme_font_size_override("font_size", 36)
	icon.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
	vbox.add_child(icon)

	var title := Label.new()
	title.text = tr("WARNING_TITLE")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(1, 0.9, 0.8))
	vbox.add_child(title)

	var body := Label.new()
	body.text = "A very small percentage of people may experience seizures or blackouts\nwhen exposed to certain light patterns or flashing lights.\n\nThis game contains visual effects including rapid flashing, particle\neffects, and screen glow that may trigger seizures in people with\nphotosensitive epilepsy.\n\nIf you or anyone in your family has an epileptic condition,\nconsult your physician before playing this game.\n\nImmediately stop playing and consult a doctor if you experience\ndizziness, altered vision, eye or muscle twitches, loss of awareness,\ndisorientation, involuntary movement, or convulsions."
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.autowrap_mode = TextServer.AUTOWRAP_WORD
	body.add_theme_font_size_override("font_size", 14)
	body.add_theme_color_override("font_color", Color(0.8, 0.8, 0.85))
	vbox.add_child(body)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(spacer)

	var btn := Button.new()
	btn.text = tr("WARNING_CONTINUE")
	btn.custom_minimum_size = Vector2(300, 50)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.add_theme_font_size_override("font_size", 18)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.25, 1)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.4, 0.4, 0.6, 1)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	btn.add_theme_stylebox_override("normal", style)
	var style_h := style.duplicate()
	style_h.bg_color = Color(0.2, 0.2, 0.35, 1)
	style_h.border_color = Color(0.5, 0.5, 0.8, 1)
	btn.add_theme_stylebox_override("hover", style_h)
	btn.pressed.connect(_on_continue)
	vbox.add_child(btn)

func _on_continue() -> void:
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
