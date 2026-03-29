extends Control
## Settings screen with language and keybinding options.

signal settings_closed

var _return_scene: String = ""

func _ready() -> void:
	_build_ui()

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.03, 0.03, 0.07, 0.95)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -350
	panel.offset_top = -280
	panel.offset_right = 350
	panel.offset_bottom = 280
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.05, 0.06, 0.12, 0.95)
	panel_style.border_width_left = 2
	panel_style.border_width_top = 2
	panel_style.border_width_right = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color(0.3, 0.4, 0.7, 0.8)
	panel_style.corner_radius_top_left = 12
	panel_style.corner_radius_top_right = 12
	panel_style.corner_radius_bottom_left = 12
	panel_style.corner_radius_bottom_right = 12
	panel_style.content_margin_left = 30
	panel_style.content_margin_right = 30
	panel_style.content_margin_top = 25
	panel_style.content_margin_bottom = 25
	panel.add_theme_stylebox_override("panel", panel_style)
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 18)
	panel.add_child(vbox)

	# Title
	var title := Label.new()
	title.text = "SETTINGS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(0.4, 0.75, 1.0))
	vbox.add_child(title)

	# --- Language section ---
	var lang_title := Label.new()
	lang_title.text = "LANGUAGE"
	lang_title.add_theme_font_size_override("font_size", 18)
	lang_title.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	vbox.add_child(lang_title)

	var lang_hbox := HBoxContainer.new()
	lang_hbox.add_theme_constant_override("separation", 10)
	for locale in LocaleManager.SUPPORTED_LOCALES:
		var lang_btn := Button.new()
		lang_btn.text = LocaleManager.get_locale_name(locale)
		lang_btn.custom_minimum_size = Vector2(80, 35)
		lang_btn.add_theme_font_size_override("font_size", 14)
		var ls := StyleBoxFlat.new()
		ls.corner_radius_top_left = 6
		ls.corner_radius_top_right = 6
		ls.corner_radius_bottom_left = 6
		ls.corner_radius_bottom_right = 6
		if locale == LocaleManager.current_locale:
			ls.bg_color = Color(0.15, 0.3, 0.5, 1)
			ls.border_color = Color(0.4, 0.7, 1.0, 1)
		else:
			ls.bg_color = Color(0.08, 0.1, 0.18, 1)
			ls.border_color = Color(0.25, 0.3, 0.5, 0.6)
		ls.border_width_left = 2
		ls.border_width_top = 2
		ls.border_width_right = 2
		ls.border_width_bottom = 2
		lang_btn.add_theme_stylebox_override("normal", ls)
		lang_btn.pressed.connect(_on_lang_select.bind(locale))
		lang_hbox.add_child(lang_btn)
	vbox.add_child(lang_hbox)

	# --- Controls section ---
	var controls_title := Label.new()
	controls_title.text = "CONTROLS"
	controls_title.add_theme_font_size_override("font_size", 18)
	controls_title.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	vbox.add_child(controls_title)

	var bindings := [
		["Move", "WASD / Arrow Keys / Left Stick"],
		["Drift", "Space / Right Trigger (RT)"],
		["Nitro Boost", "E / Left Trigger (LT)"],
		["Level Up", "Tab / Y Button"],
		["Pause", "ESC / Start Button"],
	]
	for b in bindings:
		var hbox := HBoxContainer.new()
		var action_lbl := Label.new()
		action_lbl.text = b[0]
		action_lbl.custom_minimum_size = Vector2(150, 0)
		action_lbl.add_theme_font_size_override("font_size", 14)
		action_lbl.add_theme_color_override("font_color", Color(0.8, 0.85, 0.95))
		hbox.add_child(action_lbl)
		var key_lbl := Label.new()
		key_lbl.text = b[1]
		key_lbl.add_theme_font_size_override("font_size", 14)
		key_lbl.add_theme_color_override("font_color", Color(0.55, 0.6, 0.7))
		hbox.add_child(key_lbl)
		vbox.add_child(hbox)

	# --- Gamepad info ---
	var gp_info := Label.new()
	gp_info.text = "Gamepad is auto-detected. Xbox, PS, and Switch controllers are supported."
	gp_info.autowrap_mode = TextServer.AUTOWRAP_WORD
	gp_info.add_theme_font_size_override("font_size", 12)
	gp_info.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	vbox.add_child(gp_info)

	# Spacer
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	# Back button
	var back_btn := Button.new()
	back_btn.text = "Back"
	back_btn.custom_minimum_size = Vector2(200, 45)
	back_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back_btn.add_theme_font_size_override("font_size", 18)
	var btn_style := StyleBoxFlat.new()
	btn_style.bg_color = Color(0.1, 0.12, 0.25, 1)
	btn_style.border_width_left = 2
	btn_style.border_width_top = 2
	btn_style.border_width_right = 2
	btn_style.border_width_bottom = 2
	btn_style.border_color = Color(0.3, 0.4, 0.7, 0.8)
	btn_style.corner_radius_top_left = 8
	btn_style.corner_radius_top_right = 8
	btn_style.corner_radius_bottom_left = 8
	btn_style.corner_radius_bottom_right = 8
	back_btn.add_theme_stylebox_override("normal", btn_style)
	var btn_hover := btn_style.duplicate()
	btn_hover.bg_color = Color(0.15, 0.2, 0.4, 1)
	back_btn.add_theme_stylebox_override("hover", btn_hover)
	back_btn.pressed.connect(_on_back)
	vbox.add_child(back_btn)

func _on_lang_select(locale: String) -> void:
	LocaleManager.set_locale(locale)
	# Rebuild UI to reflect new language
	for child in get_children():
		child.queue_free()
	call_deferred("_build_ui")

func _on_back() -> void:
	settings_closed.emit()
	if _return_scene != "":
		get_tree().change_scene_to_file(_return_scene)
	else:
		queue_free()
