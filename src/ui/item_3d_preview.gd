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
	var root := Node3D.new()
	var color := _get_category_color(item_data)
	var item_id: String = item_data.get("id", "")
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = 0.5
	mat.roughness = 0.3
	# Build shape based on category/type
	var cat: String = item_data.get("category", "")
	if "weapon" in item_id:
		_add_weapon_model(root, mat, item_id)
	elif cat == "defense":
		_add_shield_model(root, mat)
	elif cat == "offense":
		_add_sword_model(root, mat, color)
	elif cat == "speed":
		_add_bolt_model(root, mat, color)
	elif cat == "special":
		_add_star_model(root, mat, color)
	else:
		_add_crystal_model(root, mat, color)
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

func _add_shield_model(root: Node3D, mat: StandardMaterial3D) -> void:
	var shield := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.6, 0.7, 0.08)
	shield.mesh = mesh
	shield.position = Vector3(0, 0.4, 0)
	shield.material_override = mat
	root.add_child(shield)
	# Cross detail
	var cross_mat := StandardMaterial3D.new()
	cross_mat.albedo_color = Color(1, 1, 1)
	cross_mat.emission_enabled = true
	cross_mat.emission = mat.albedo_color
	cross_mat.emission_energy_multiplier = 1.5
	var h := MeshInstance3D.new()
	h.mesh = BoxMesh.new()
	h.mesh.size = Vector3(0.3, 0.06, 0.02)
	h.position = Vector3(0, 0.4, 0.05)
	h.material_override = cross_mat
	root.add_child(h)
	var v := MeshInstance3D.new()
	v.mesh = BoxMesh.new()
	v.mesh.size = Vector3(0.06, 0.3, 0.02)
	v.position = Vector3(0, 0.4, 0.05)
	v.material_override = cross_mat
	root.add_child(v)

func _add_sword_model(root: Node3D, mat: StandardMaterial3D, color: Color) -> void:
	# Blade
	var blade := MeshInstance3D.new()
	blade.mesh = BoxMesh.new()
	blade.mesh.size = Vector3(0.08, 0.7, 0.04)
	blade.position = Vector3(0, 0.55, 0)
	blade.material_override = mat
	root.add_child(blade)
	# Guard
	var guard := MeshInstance3D.new()
	guard.mesh = BoxMesh.new()
	guard.mesh.size = Vector3(0.3, 0.06, 0.06)
	guard.position = Vector3(0, 0.2, 0)
	guard.material_override = mat
	root.add_child(guard)
	# Handle
	var grip_mat := StandardMaterial3D.new()
	grip_mat.albedo_color = Color(0.2, 0.15, 0.1)
	var grip := MeshInstance3D.new()
	grip.mesh = CylinderMesh.new()
	grip.mesh.top_radius = 0.04
	grip.mesh.bottom_radius = 0.04
	grip.mesh.height = 0.2
	grip.position = Vector3(0, 0.1, 0)
	grip.material_override = grip_mat
	root.add_child(grip)
	# Tip glow
	var tip_mat := StandardMaterial3D.new()
	tip_mat.emission_enabled = true
	tip_mat.emission = color
	tip_mat.emission_energy_multiplier = 2.0
	tip_mat.albedo_color = color
	var tip := MeshInstance3D.new()
	tip.mesh = SphereMesh.new()
	tip.mesh.radius = 0.05
	tip.mesh.height = 0.1
	tip.position = Vector3(0, 0.9, 0)
	tip.material_override = tip_mat
	root.add_child(tip)

func _add_bolt_model(root: Node3D, mat: StandardMaterial3D, color: Color) -> void:
	# Lightning bolt shape (zigzag boxes)
	for i in 3:
		var seg := MeshInstance3D.new()
		seg.mesh = BoxMesh.new()
		seg.mesh.size = Vector3(0.25, 0.12, 0.06)
		var y := 0.2 + i * 0.25
		var x := 0.1 if i % 2 == 0 else -0.1
		seg.position = Vector3(x, y, 0)
		seg.rotation_degrees.z = -30.0 if i % 2 == 0 else 30.0
		seg.material_override = mat
		root.add_child(seg)
	var glow_mat := StandardMaterial3D.new()
	glow_mat.albedo_color = color
	glow_mat.emission_enabled = true
	glow_mat.emission = color
	glow_mat.emission_energy_multiplier = 3.0
	var glow := MeshInstance3D.new()
	glow.mesh = SphereMesh.new()
	glow.mesh.radius = 0.08
	glow.mesh.height = 0.16
	glow.position = Vector3(0, 0.45, 0)
	glow.material_override = glow_mat
	root.add_child(glow)

func _add_star_model(root: Node3D, mat: StandardMaterial3D, color: Color) -> void:
	# Central sphere + orbiting points
	var center := MeshInstance3D.new()
	center.mesh = SphereMesh.new()
	center.mesh.radius = 0.2
	center.mesh.height = 0.4
	center.position = Vector3(0, 0.45, 0)
	var glow_mat := StandardMaterial3D.new()
	glow_mat.albedo_color = color
	glow_mat.emission_enabled = true
	glow_mat.emission = color
	glow_mat.emission_energy_multiplier = 3.0
	center.material_override = glow_mat
	root.add_child(center)
	# Spikes
	for angle in [0, TAU/3, TAU*2/3]:
		var spike := MeshInstance3D.new()
		spike.mesh = BoxMesh.new()
		spike.mesh.size = Vector3(0.06, 0.3, 0.06)
		spike.position = Vector3(cos(angle) * 0.15, 0.45, sin(angle) * 0.15)
		spike.rotation_degrees.z = rad_to_deg(angle) - 90
		spike.material_override = mat
		root.add_child(spike)

func _add_crystal_model(root: Node3D, mat: StandardMaterial3D, color: Color) -> void:
	# Rotated box = diamond
	var crystal := MeshInstance3D.new()
	crystal.mesh = BoxMesh.new()
	crystal.mesh.size = Vector3(0.35, 0.5, 0.35)
	crystal.position = Vector3(0, 0.4, 0)
	crystal.rotation_degrees = Vector3(0, 45, 0)
	crystal.material_override = mat
	root.add_child(crystal)
	var glow_mat := StandardMaterial3D.new()
	glow_mat.albedo_color = color
	glow_mat.emission_enabled = true
	glow_mat.emission = color
	glow_mat.emission_energy_multiplier = 2.0
	var glow := MeshInstance3D.new()
	glow.mesh = SphereMesh.new()
	glow.mesh.radius = 0.1
	glow.mesh.height = 0.2
	glow.position = Vector3(0, 0.65, 0)
	glow.material_override = glow_mat
	root.add_child(glow)

func _add_weapon_model(root: Node3D, mat: StandardMaterial3D, weapon_id: String) -> void:
	var barrel := MeshInstance3D.new()
	barrel.mesh = CylinderMesh.new()
	barrel.mesh.top_radius = 0.04
	barrel.mesh.bottom_radius = 0.05
	barrel.mesh.height = 0.5
	barrel.rotation_degrees = Vector3(90, 0, 0)
	barrel.position = Vector3(0, 0.35, -0.2)
	barrel.material_override = mat
	root.add_child(barrel)
	var body := MeshInstance3D.new()
	body.mesh = BoxMesh.new()
	body.mesh.size = Vector3(0.12, 0.12, 0.25)
	body.position = Vector3(0, 0.35, 0.08)
	body.material_override = mat
	root.add_child(body)
