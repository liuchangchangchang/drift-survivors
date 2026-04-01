extends Control
## Car selection screen - Overwatch-style hero select.
## Square cards at bottom, 3D preview with rotation in center.

signal car_selected(car_id: String)

var _preview_viewport: SubViewport
var _preview_root: Node3D
var _preview_model: Node3D
var _selected_id: String = ""
var _card_buttons: Array[Button] = []
var _info_label: Label
var _stats_label: Label
var _confirm_btn: Button


func _ready() -> void:
	_setup_background()
	_setup_3d_preview()
	_setup_title()
	_setup_info_panel()
	_setup_card_bar()
	_setup_confirm_button()
	# Auto-select first car
	if DataLoader.cars.size() > 0:
		_select_car(DataLoader.cars[0].get("id", "car_starter"), 0)

func _process(_delta: float) -> void:
	if _preview_model:
		_preview_model.rotation.y += _delta * 0.8

func _setup_background() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.04, 0.08, 1)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

func _setup_title() -> void:
	var title := Label.new()
	title.text = tr("SELECT_CAR")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.set_anchors_preset(Control.PRESET_CENTER_TOP)
	title.position = Vector2(-200, 30)
	title.size = Vector2(400, 50)
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color(0.4, 0.75, 1.0))
	add_child(title)

func _setup_info_panel() -> void:
	# Car name
	_info_label = Label.new()
	_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_info_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_info_label.position = Vector2(-200, 85)
	_info_label.size = Vector2(400, 40)
	_info_label.add_theme_font_size_override("font_size", 28)
	_info_label.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	add_child(_info_label)
	# Stats
	_stats_label = Label.new()
	_stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stats_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_stats_label.position = Vector2(-300, 125)
	_stats_label.size = Vector2(600, 80)
	_stats_label.add_theme_font_size_override("font_size", 16)
	_stats_label.add_theme_color_override("font_color", Color(0.7, 0.75, 0.85))
	add_child(_stats_label)

func _setup_3d_preview() -> void:
	# SubViewport for 3D rendering
	_preview_viewport = SubViewport.new()
	_preview_viewport.size = Vector2i(800, 500)
	_preview_viewport.transparent_bg = true
	_preview_viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	# 3D scene inside viewport
	_preview_root = Node3D.new()
	# Camera
	var cam := Camera3D.new()
	cam.position = Vector3(0, 2.0, 7.0)
	cam.look_at(Vector3(0, 0.3, 0))
	cam.fov = 40
	var cam_env := Environment.new()
	cam_env.background_mode = Environment.BG_COLOR
	cam_env.background_color = Color(0, 0, 0, 0)
	cam_env.ambient_light_color = Color(0.3, 0.35, 0.5)
	cam_env.ambient_light_energy = 0.6
	cam.environment = cam_env
	_preview_root.add_child(cam)
	# Lighting
	var key_light := DirectionalLight3D.new()
	key_light.rotation_degrees = Vector3(-45, -30, 0)
	key_light.light_energy = 1.2
	key_light.light_color = Color(1, 0.95, 0.9)
	_preview_root.add_child(key_light)
	var fill_light := DirectionalLight3D.new()
	fill_light.rotation_degrees = Vector3(-20, 150, 0)
	fill_light.light_energy = 0.4
	fill_light.light_color = Color(0.6, 0.7, 1.0)
	_preview_root.add_child(fill_light)
	_preview_viewport.add_child(_preview_root)
	add_child(_preview_viewport)
	# Display viewport on screen with TextureRect
	var tex_rect := TextureRect.new()
	tex_rect.texture = _preview_viewport.get_texture()
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex_rect.anchor_left = 0.15
	tex_rect.anchor_right = 0.85
	tex_rect.anchor_top = 0.15
	tex_rect.anchor_bottom = 0.7
	tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tex_rect)

func _setup_card_bar() -> void:
	var bar := HBoxContainer.new()
	bar.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	bar.alignment = BoxContainer.ALIGNMENT_CENTER
	bar.add_theme_constant_override("separation", 20)
	var card_count := DataLoader.cars.size()
	var total_w := card_count * 140 + (card_count - 1) * 20
	bar.position = Vector2(-total_w / 2.0, -220)
	bar.size = Vector2(total_w, 140)
	for i in DataLoader.cars.size():
		var car_data: Dictionary = DataLoader.cars[i]
		var car_id: String = car_data.get("id", "")
		var car_name: String = car_data.get("name", "")
		var btn := Button.new()
		btn.text = car_name
		btn.custom_minimum_size = Vector2(140, 140)
		btn.add_theme_font_size_override("font_size", 14)
		btn.add_theme_color_override("font_color", Color(0.85, 0.9, 1.0))
		btn.add_theme_color_override("font_hover_color", Color(1, 1, 1))
		# Style
		var style_n := StyleBoxFlat.new()
		style_n.bg_color = Color(0.08, 0.1, 0.18, 0.9)
		style_n.border_width_left = 2
		style_n.border_width_top = 2
		style_n.border_width_right = 2
		style_n.border_width_bottom = 2
		style_n.border_color = Color(0.25, 0.35, 0.6, 0.8)
		style_n.corner_radius_top_left = 6
		style_n.corner_radius_top_right = 6
		style_n.corner_radius_bottom_left = 6
		style_n.corner_radius_bottom_right = 6
		btn.add_theme_stylebox_override("normal", style_n)
		var style_h := style_n.duplicate()
		style_h.bg_color = Color(0.12, 0.18, 0.35, 1)
		style_h.border_color = Color(0.4, 0.6, 1.0, 1)
		btn.add_theme_stylebox_override("hover", style_h)
		var style_p := style_n.duplicate()
		style_p.bg_color = Color(0.15, 0.25, 0.5, 1)
		style_p.border_color = Color(0.5, 0.8, 1.0, 1)
		btn.add_theme_stylebox_override("pressed", style_p)
		btn.pressed.connect(_select_car.bind(car_id, i))
		_card_buttons.append(btn)
		bar.add_child(btn)
	add_child(bar)

func _setup_confirm_button() -> void:
	_confirm_btn = Button.new()
	_confirm_btn.text = tr("CONFIRM")
	_confirm_btn.custom_minimum_size = Vector2(200, 50)
	_confirm_btn.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_confirm_btn.position = Vector2(-100, -50)
	_confirm_btn.size = Vector2(200, 50)
	_confirm_btn.add_theme_font_size_override("font_size", 22)
	_confirm_btn.add_theme_color_override("font_color", Color(0.9, 0.95, 1))
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.4, 0.2, 1)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.3, 0.8, 0.4, 1)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	_confirm_btn.add_theme_stylebox_override("normal", style)
	var style_h := style.duplicate()
	style_h.bg_color = Color(0.15, 0.55, 0.3, 1)
	style_h.border_color = Color(0.4, 1.0, 0.5, 1)
	_confirm_btn.add_theme_stylebox_override("hover", style_h)
	_confirm_btn.pressed.connect(_on_confirm)
	add_child(_confirm_btn)

func _select_car(car_id: String, index: int) -> void:
	_selected_id = car_id
	var car_data := DataLoader.get_car_data(car_id)
	_info_label.text = car_data.get("name", car_id)
	var stats: Dictionary = car_data.get("base_stats", {})
	var parts: Array[String] = []
	parts.append(tr("STATS_HP") % int(stats.get("max_hp", 0)))
	parts.append(tr("STATS_SPEED") % int(stats.get("max_speed", 0)))
	parts.append(tr("STATS_ACCEL") % int(stats.get("base_accel", 0)))
	parts.append(tr("STATS_NITRO") % int(stats.get("nitro_max", 0)))
	parts.append(tr("STATS_ARMOR") % int(stats.get("armor", 0)))
	parts.append(tr("STATS_SLOTS") % int(stats.get("weapon_slots", 4)))
	_stats_label.text = "  |  ".join(parts)
	# Highlight selected card
	for i in _card_buttons.size():
		var btn := _card_buttons[i]
		var s: StyleBoxFlat = btn.get_theme_stylebox("normal")
		if i == index:
			s.border_color = Color(0.5, 0.8, 1.0, 1)
			s.bg_color = Color(0.15, 0.25, 0.5, 1)
		else:
			s.border_color = Color(0.25, 0.35, 0.6, 0.8)
			s.bg_color = Color(0.08, 0.1, 0.18, 0.9)
	# Build 3D preview
	_build_car_preview(car_id, stats)

func _build_car_preview(car_id: String, _stats: Dictionary) -> void:
	if _preview_model:
		_preview_model.queue_free()
	# Instance car scene from content directory
	var car_scene: PackedScene = DataLoader.get_car_scene(car_id)
	if car_scene:
		_preview_model = car_scene.instantiate()
	else:
		_preview_model = Node3D.new()
	# Ground platform
	var platform := MeshInstance3D.new()
	var plat_mesh := CylinderMesh.new()
	plat_mesh.top_radius = 2.2
	plat_mesh.bottom_radius = 2.4
	plat_mesh.height = 0.08
	platform.mesh = plat_mesh
	platform.position = Vector3(0, -0.04, 0)
	var plat_mat := StandardMaterial3D.new()
	plat_mat.albedo_color = Color(0.1, 0.15, 0.25, 0.8)
	plat_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	plat_mat.emission_enabled = true
	plat_mat.emission = Color(0.15, 0.3, 0.6)
	plat_mat.emission_energy_multiplier = 0.5
	platform.material_override = plat_mat
	_preview_model.add_child(platform)
	_preview_root.add_child(_preview_model)

func _on_confirm() -> void:
	if _selected_id != "":
		car_selected.emit(_selected_id)
		GameManager.select_car(_selected_id)
