extends Control
## Settings screen with language selection and interactive key rebinding.

signal settings_closed

var _return_scene: String = ""
var _waiting_for_key: String = ""  # Action name currently being rebound
var _rebind_btn: Button = null     # The button waiting for input
var _rebind_buttons: Dictionary = {}  # action_name → Button

const REBINDABLE_ACTIONS := [
	["drift", "Drift"],
	["nitro_boost", "Nitro Boost"],
	["level_up_open", "Level Up"],
	["pause", "Pause"],
]

func _ready() -> void:
	_build_ui()

func _unhandled_input(event: InputEvent) -> void:
	if _waiting_for_key.is_empty():
		return
	# Accept keyboard or gamepad input for rebinding
	if event is InputEventKey and event.pressed:
		_apply_rebind(_waiting_for_key, event)
		get_viewport().set_input_as_handled()
	elif event is InputEventJoypadButton and event.pressed:
		_apply_rebind(_waiting_for_key, event)
		get_viewport().set_input_as_handled()

func _apply_rebind(action: String, event: InputEvent) -> void:
	# Remove old events of same type (keep other type)
	var old_events := InputMap.action_get_events(action)
	for ev in old_events:
		if (event is InputEventKey and ev is InputEventKey) or \
		   (event is InputEventJoypadButton and ev is InputEventJoypadButton):
			InputMap.action_erase_event(action, ev)
	# Add new event
	InputMap.action_add_event(action, event)
	# Update button text
	if _rebind_btn:
		_rebind_btn.text = _get_action_key_text(action)
	_waiting_for_key = ""
	_rebind_btn = null

func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.03, 0.03, 0.07, 0.95)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_CENTER)
	scroll.offset_left = -380
	scroll.offset_top = -300
	scroll.offset_right = 380
	scroll.offset_bottom = 300
	add_child(scroll)

	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
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
	scroll.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	panel.add_child(vbox)

	# Title
	var title := Label.new()
	title.text = tr("SETTINGS_TITLE")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(0.4, 0.75, 1.0))
	vbox.add_child(title)

	# === Language section ===
	var lang_title := Label.new()
	lang_title.text = tr("SETTINGS_LANGUAGE")
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

	# === Key Bindings section ===
	var ctrl_title := Label.new()
	ctrl_title.text = tr("SETTINGS_CONTROLS")
	ctrl_title.add_theme_font_size_override("font_size", 18)
	ctrl_title.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	vbox.add_child(ctrl_title)

	var hint := Label.new()
	hint.text = "Click a key binding, then press a new key or gamepad button to rebind."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD
	hint.add_theme_font_size_override("font_size", 12)
	hint.add_theme_color_override("font_color", Color(0.5, 0.55, 0.65))
	vbox.add_child(hint)

	# Movement (not rebindable, just info)
	var move_row := HBoxContainer.new()
	var move_lbl := Label.new()
	move_lbl.text = "Move"
	move_lbl.custom_minimum_size = Vector2(160, 0)
	move_lbl.add_theme_font_size_override("font_size", 15)
	move_lbl.add_theme_color_override("font_color", Color(0.8, 0.85, 0.95))
	move_row.add_child(move_lbl)
	var move_val := Label.new()
	move_val.text = "WASD / Arrows / Left Stick"
	move_val.add_theme_font_size_override("font_size", 14)
	move_val.add_theme_color_override("font_color", Color(0.55, 0.6, 0.7))
	move_row.add_child(move_val)
	vbox.add_child(move_row)

	# Rebindable actions
	var btn_style_normal := StyleBoxFlat.new()
	btn_style_normal.bg_color = Color(0.08, 0.1, 0.2, 1)
	btn_style_normal.border_width_left = 1
	btn_style_normal.border_width_top = 1
	btn_style_normal.border_width_right = 1
	btn_style_normal.border_width_bottom = 1
	btn_style_normal.border_color = Color(0.3, 0.4, 0.6, 0.7)
	btn_style_normal.corner_radius_top_left = 4
	btn_style_normal.corner_radius_top_right = 4
	btn_style_normal.corner_radius_bottom_left = 4
	btn_style_normal.corner_radius_bottom_right = 4
	var btn_style_hover := btn_style_normal.duplicate()
	btn_style_hover.bg_color = Color(0.12, 0.18, 0.35, 1)
	btn_style_hover.border_color = Color(0.4, 0.6, 1.0, 1)

	for entry in REBINDABLE_ACTIONS:
		var action_name: String = entry[0]
		var display_name: String = entry[1]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 15)
		var lbl := Label.new()
		lbl.text = display_name
		lbl.custom_minimum_size = Vector2(160, 0)
		lbl.add_theme_font_size_override("font_size", 15)
		lbl.add_theme_color_override("font_color", Color(0.8, 0.85, 0.95))
		row.add_child(lbl)
		var key_btn := Button.new()
		key_btn.text = _get_action_key_text(action_name)
		key_btn.custom_minimum_size = Vector2(250, 32)
		key_btn.add_theme_font_size_override("font_size", 14)
		key_btn.add_theme_stylebox_override("normal", btn_style_normal.duplicate())
		key_btn.add_theme_stylebox_override("hover", btn_style_hover.duplicate())
		key_btn.pressed.connect(_on_rebind_start.bind(action_name, key_btn))
		row.add_child(key_btn)
		_rebind_buttons[action_name] = key_btn
		vbox.add_child(row)

	# Spacer
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(spacer)

	# Back button
	var back_btn := Button.new()
	back_btn.text = tr("SETTINGS_BACK")
	back_btn.custom_minimum_size = Vector2(200, 45)
	back_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	back_btn.add_theme_font_size_override("font_size", 18)
	var back_style := StyleBoxFlat.new()
	back_style.bg_color = Color(0.1, 0.12, 0.25, 1)
	back_style.border_width_left = 2
	back_style.border_width_top = 2
	back_style.border_width_right = 2
	back_style.border_width_bottom = 2
	back_style.border_color = Color(0.3, 0.4, 0.7, 0.8)
	back_style.corner_radius_top_left = 8
	back_style.corner_radius_top_right = 8
	back_style.corner_radius_bottom_left = 8
	back_style.corner_radius_bottom_right = 8
	back_btn.add_theme_stylebox_override("normal", back_style)
	var back_hover := back_style.duplicate()
	back_hover.bg_color = Color(0.15, 0.2, 0.4, 1)
	back_btn.add_theme_stylebox_override("hover", back_hover)
	back_btn.pressed.connect(_on_back)
	vbox.add_child(back_btn)

func _on_rebind_start(action_name: String, btn: Button) -> void:
	# Cancel previous rebind if any
	if _rebind_btn and _rebind_btn != btn:
		_rebind_btn.text = _get_action_key_text(_waiting_for_key)
	_waiting_for_key = action_name
	_rebind_btn = btn
	btn.text = "... Press a key ..."

func _get_action_key_text(action: String) -> String:
	if not InputMap.has_action(action):
		return "???"
	var parts: Array[String] = []
	for ev in InputMap.action_get_events(action):
		if ev is InputEventKey:
			parts.append(OS.get_keycode_string(ev.keycode))
		elif ev is InputEventJoypadButton:
			parts.append("Pad: " + _joy_button_name(ev.button_index))
		elif ev is InputEventJoypadMotion:
			var dir := "+" if ev.axis_value > 0 else "-"
			parts.append("Axis" + str(ev.axis) + dir)
	if parts.is_empty():
		return "Unbound"
	return " / ".join(parts)

func _joy_button_name(idx: int) -> String:
	match idx:
		JOY_BUTTON_A: return "A"
		JOY_BUTTON_B: return "B"
		JOY_BUTTON_X: return "X"
		JOY_BUTTON_Y: return "Y"
		JOY_BUTTON_START: return "Start"
		JOY_BUTTON_BACK: return "Select"
		JOY_BUTTON_LEFT_SHOULDER: return "LB"
		JOY_BUTTON_RIGHT_SHOULDER: return "RB"
	return "Btn" + str(idx)

func _on_lang_select(locale: String) -> void:
	LocaleManager.set_locale(locale)
	for child in get_children():
		child.queue_free()
	_rebind_buttons.clear()
	call_deferred("_build_ui")

func _on_back() -> void:
	settings_closed.emit()
	if _return_scene != "":
		get_tree().change_scene_to_file(_return_scene)
	else:
		queue_free()
