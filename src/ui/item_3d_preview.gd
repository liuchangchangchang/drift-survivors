class_name Item3DPreview
extends SubViewportContainer
## Small 3D preview for an item/upgrade, shown inside UI cards.

var _viewport: SubViewport
var _model: Node3D
var _root: Node3D

func _init() -> void:
	stretch = true
	custom_minimum_size = Vector2(120, 100)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func setup(item_data: Dictionary) -> void:
	_viewport = SubViewport.new()
	_viewport.size = Vector2i(240, 200)
	_viewport.transparent_bg = true
	_viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	_root = Node3D.new()
	# Camera (use camera.environment instead of WorldEnvironment to avoid conflicts)
	var cam := Camera3D.new()
	cam.position = Vector3(0, 0.8, 1.8)
	cam.look_at(Vector3(0, 0.35, 0))
	cam.fov = 45
	var cam_env := Environment.new()
	cam_env.background_mode = Environment.BG_COLOR
	cam_env.background_color = Color(0, 0, 0, 0)
	cam_env.ambient_light_color = Color(0.4, 0.45, 0.6)
	cam_env.ambient_light_energy = 0.8
	cam.environment = cam_env
	_root.add_child(cam)
	# Lighting
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45, -30, 0)
	light.light_energy = 1.5
	_root.add_child(light)
	# Build model
	_model = _build_model(item_data)
	_root.add_child(_model)
	_viewport.add_child(_root)
	add_child(_viewport)

func _process(delta: float) -> void:
	if _model:
		_model.rotation.y += delta * 1.5

static func _get_category_color(item_data: Dictionary) -> Color:
	var cat: String = item_data.get("category", "")
	match cat:
		"defense": return Color(0.3, 0.5, 0.9)
		"offense": return Color(0.9, 0.3, 0.2)
		"speed": return Color(0.2, 0.9, 0.3)
		"utility": return Color(0.9, 0.8, 0.2)
		"special": return Color(0.8, 0.3, 0.9)
	# Upgrades by rarity
	var rarity: String = item_data.get("rarity", "common")
	match rarity:
		"common": return Color(0.6, 0.6, 0.7)
		"uncommon": return Color(0.2, 0.8, 0.3)
		"rare": return Color(0.3, 0.5, 1.0)
		"legendary": return Color(1.0, 0.7, 0.1)
	return Color(0.5, 0.5, 0.6)

func _build_model(item_data: Dictionary) -> Node3D:
	var item_id: String = item_data.get("id", "")
	var root: Node3D = null
	# Try to load from content scene
	var item_scene: PackedScene = DataLoader.get_item_scene(item_id)
	if item_scene == null:
		item_scene = DataLoader.get_upgrade_scene(item_id)
	if item_scene:
		root = item_scene.instantiate()
	else:
		root = Node3D.new()
	# Platform
	var plat := MeshInstance3D.new()
	var plat_mesh := CylinderMesh.new()
	plat_mesh.top_radius = 0.5
	plat_mesh.bottom_radius = 0.55
	plat_mesh.height = 0.04
	plat.mesh = plat_mesh
	plat.position = Vector3(0, -0.02, 0)
	var plat_mat := StandardMaterial3D.new()
	plat_mat.albedo_color = Color(0.1, 0.12, 0.2, 0.6)
	plat_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	plat.material_override = plat_mat
	root.add_child(plat)
	return root
