## Run with: godot --headless -s tools/generate_content_scenes.gd
## Generates all content .tscn files from JSON data + procedural visuals.
extends SceneTree

func _init() -> void:
	_generate_cars()
	_generate_weapons()
	_generate_items()
	_generate_upgrades()
	print("All content scenes generated.")
	quit()

# ─── CARS ──────────────────────────────────────────────────────

func _generate_cars() -> void:
	var json := _load_json("res://data/cars.json")
	var colors := {
		"car_starter": Color(0.15, 0.5, 0.95),
		"car_speed": Color(0.95, 0.8, 0.1),
		"car_tank": Color(0.4, 0.6, 0.4),
		"car_drift": Color(0.9, 0.15, 0.3),
	}
	for car_data: Dictionary in json["cars"]:
		var root := CarScene.new()
		var cid: String = car_data["id"]
		root.id = cid
		root.car_name = car_data["name"]
		root.unlock_condition = car_data.get("unlock_condition", "none")
		var bs: Dictionary = car_data["base_stats"]
		root.max_hp = bs.get("max_hp", 100.0)
		root.hp_regen = bs.get("hp_regen", 1.0)
		root.armor = bs.get("armor", 0.0)
		root.max_speed = bs.get("max_speed", 28.0)
		root.boost_speed = bs.get("boost_speed", 45.0)
		root.base_accel = bs.get("base_accel", 35.0)
		root.friction = bs.get("friction", 0.98)
		root.normal_grip = bs.get("normal_grip", 0.15)
		root.drift_grip = bs.get("drift_grip", 0.02)
		root.turn_speed_normal = bs.get("turn_speed_normal", 8.0)
		root.turn_speed_drift = bs.get("turn_speed_drift", 12.0)
		root.charge_rate = bs.get("charge_rate", 50.0)
		root.max_charge = bs.get("max_charge", 100.0)
		root.boost_duration = bs.get("boost_duration", 1.5)
		root.nitro_max = bs.get("nitro_max", 100.0)
		root.nitro_accumulation_rate = bs.get("nitro_accumulation_rate", 10.0)
		root.nitro_drain_rate = bs.get("nitro_drain_rate", 25.0)
		root.nitro_damage = bs.get("nitro_damage", 30.0)
		root.weapon_slots = int(bs.get("weapon_slots", 4))
		_build_car_visual(root, colors.get(cid, Color(0.5, 0.5, 0.5)))
		_save_scene(root, "res://scenes/content/cars/%s.tscn" % cid)
		root.free()
	print("  Cars: %d generated" % json["cars"].size())

func _build_car_visual(root: Node3D, body_color: Color) -> void:
	var body_wrap := Node3D.new()
	body_wrap.name = "BodyWrap"

	# Chassis
	var chassis := MeshInstance3D.new()
	chassis.name = "Chassis"
	var chassis_mesh := BoxMesh.new()
	chassis_mesh.size = Vector3(1.8, 0.5, 2.8)
	chassis.mesh = chassis_mesh
	chassis.position = Vector3(0, 0.35, 0)
	var chassis_mat := StandardMaterial3D.new()
	chassis_mat.albedo_color = body_color
	chassis_mat.metallic = 0.6
	chassis_mat.roughness = 0.3
	chassis.material_override = chassis_mat
	body_wrap.add_child(chassis)
	chassis.owner = root

	# Cabin
	var cabin := MeshInstance3D.new()
	cabin.name = "Cabin"
	var cabin_mesh := BoxMesh.new()
	cabin_mesh.size = Vector3(1.4, 0.4, 1.4)
	cabin.mesh = cabin_mesh
	cabin.position = Vector3(0, 0.75, 0.15)
	var cabin_mat := StandardMaterial3D.new()
	cabin_mat.albedo_color = Color(0.3, 0.7, 1.0, 0.8)
	cabin_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	cabin_mat.metallic = 0.8
	cabin_mat.roughness = 0.1
	cabin.material_override = cabin_mat
	body_wrap.add_child(cabin)
	cabin.owner = root

	# Headlights
	var hl_mat := StandardMaterial3D.new()
	hl_mat.albedo_color = Color(1.0, 1.0, 0.8)
	hl_mat.emission_enabled = true
	hl_mat.emission = Color(1.0, 1.0, 0.8)
	hl_mat.emission_energy_multiplier = 3.0
	for side_i in 2:
		var side_x := -0.65 if side_i == 0 else 0.65
		var hl := MeshInstance3D.new()
		hl.name = "HeadlightL" if side_i == 0 else "HeadlightR"
		var hl_mesh := BoxMesh.new()
		hl_mesh.size = Vector3(0.3, 0.15, 0.1)
		hl.mesh = hl_mesh
		hl.position = Vector3(side_x, 0.45, -1.45)
		hl.material_override = hl_mat
		body_wrap.add_child(hl)
		hl.owner = root

	# Taillights
	var tl_mat := StandardMaterial3D.new()
	tl_mat.albedo_color = Color(1.0, 0.1, 0.1)
	tl_mat.emission_enabled = true
	tl_mat.emission = Color(1.0, 0.1, 0.1)
	tl_mat.emission_energy_multiplier = 2.0
	for side_i in 2:
		var side_x := -0.7 if side_i == 0 else 0.7
		var tl := MeshInstance3D.new()
		tl.name = "TaillightL" if side_i == 0 else "TaillightR"
		var tl_mesh := BoxMesh.new()
		tl_mesh.size = Vector3(0.25, 0.12, 0.08)
		tl.mesh = tl_mesh
		tl.position = Vector3(side_x, 0.4, 1.45)
		tl.material_override = tl_mat
		body_wrap.add_child(tl)
		tl.owner = root

	root.add_child(body_wrap)
	body_wrap.owner = root

	# Wheels
	var wheel_mat := StandardMaterial3D.new()
	wheel_mat.albedo_color = Color(0.15, 0.15, 0.15)
	wheel_mat.roughness = 0.9
	var wheel_positions := [
		Vector3(-1.0, 0.2, -0.9),
		Vector3(1.0, 0.2, -0.9),
		Vector3(-1.0, 0.2, 0.9),
		Vector3(1.0, 0.2, 0.9),
	]
	var wheel_names := ["WheelFL", "WheelFR", "WheelRL", "WheelRR"]
	for i in wheel_positions.size():
		var wheel := MeshInstance3D.new()
		wheel.name = wheel_names[i]
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.25
		cyl.bottom_radius = 0.25
		cyl.height = 0.2
		wheel.mesh = cyl
		wheel.position = wheel_positions[i]
		wheel.rotation_degrees = Vector3(0, 0, 90)
		wheel.material_override = wheel_mat
		root.add_child(wheel)
		wheel.owner = root

	# Boost exhaust particles
	for pipe_i in 2:
		var pipe_x := -0.5 if pipe_i == 0 else 0.5
		var exhaust := GPUParticles3D.new()
		exhaust.name = "BoostExhaustL" if pipe_i == 0 else "BoostExhaustR"
		exhaust.emitting = false
		exhaust.amount = 60
		exhaust.lifetime = 0.5
		exhaust.speed_scale = 1.5
		exhaust.visibility_aabb = AABB(Vector3(-5, -2, -5), Vector3(10, 5, 10))
		var ex_mat := ParticleProcessMaterial.new()
		ex_mat.direction = Vector3(0, 0.3, 1)
		ex_mat.spread = 12.0
		ex_mat.initial_velocity_min = 12.0
		ex_mat.initial_velocity_max = 22.0
		ex_mat.gravity = Vector3(0, 3, 0)
		ex_mat.scale_min = 0.3
		ex_mat.scale_max = 0.8
		ex_mat.color = Color(1.0, 0.5, 0.1)
		exhaust.process_material = ex_mat
		var ex_draw_mat := StandardMaterial3D.new()
		ex_draw_mat.albedo_color = Color(1.0, 0.6, 0.1)
		ex_draw_mat.emission_enabled = true
		ex_draw_mat.emission = Color(1.0, 0.4, 0.05)
		ex_draw_mat.emission_energy_multiplier = 5.0
		ex_draw_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		ex_draw_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		var ex_draw := QuadMesh.new()
		ex_draw.size = Vector2(0.5, 0.5)
		ex_draw.material = ex_draw_mat
		exhaust.draw_pass_1 = ex_draw
		exhaust.position = Vector3(pipe_x, 0.25, 1.5)
		root.add_child(exhaust)
		exhaust.owner = root

	# Drift sparks
	for spark_i in 2:
		var spark_x := -0.9 if spark_i == 0 else 0.9
		var sparks := GPUParticles3D.new()
		sparks.name = "DriftSparksL" if spark_i == 0 else "DriftSparksR"
		sparks.emitting = false
		sparks.amount = 30
		sparks.lifetime = 0.35
		sparks.visibility_aabb = AABB(Vector3(-4, -2, -4), Vector3(8, 5, 8))
		var sp_mat := ParticleProcessMaterial.new()
		sp_mat.direction = Vector3(0, 1, 0)
		sp_mat.spread = 50.0
		sp_mat.initial_velocity_min = 4.0
		sp_mat.initial_velocity_max = 10.0
		sp_mat.gravity = Vector3(0, -20, 0)
		sp_mat.scale_min = 0.04
		sp_mat.scale_max = 0.12
		sp_mat.color = Color(1.0, 0.7, 0.2)
		sparks.process_material = sp_mat
		var sp_draw_mat := StandardMaterial3D.new()
		sp_draw_mat.emission_enabled = true
		sp_draw_mat.emission = Color(1.0, 0.7, 0.2)
		sp_draw_mat.emission_energy_multiplier = 4.0
		sp_draw_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		var sp_draw := QuadMesh.new()
		sp_draw.size = Vector2(0.08, 0.08)
		sp_draw.material = sp_draw_mat
		sparks.draw_pass_1 = sp_draw
		sparks.position = Vector3(spark_x, 0.1, 0.9)
		root.add_child(sparks)
		sparks.owner = root

# ─── WEAPONS ──────────────────────────────────────────────────

func _generate_weapons() -> void:
	var json := _load_json("res://data/weapons.json")
	var weapon_colors := {
		"weapon_pistol": Color(0.6, 0.6, 0.65),
		"weapon_shotgun": Color(0.8, 0.5, 0.2),
		"weapon_smg": Color(0.3, 0.35, 0.4),
		"weapon_sniper": Color(0.2, 0.3, 0.6),
		"weapon_bumper": Color(0.5, 0.5, 0.55),
		"weapon_laser": Color(0.2, 0.8, 0.4),
	}
	for w_data: Dictionary in json["weapons"]:
		var root := WeaponScene.new()
		var wid: String = w_data["id"]
		root.id = wid
		root.weapon_name = w_data["name"]
		root.type = w_data["type"]
		root.damage_type = w_data.get("damage_type", w_data["type"])
		root.can_be_starting_weapon = w_data.get("can_be_starting_weapon", true)
		# Tiers
		root.tiers = []
		for t_data: Dictionary in w_data["tiers"]:
			var td := WeaponTierData.new()
			td.tier = int(t_data["tier"])
			td.damage = t_data["damage"]
			td.fire_rate = t_data["fire_rate"]
			td.weapon_range = t_data["range"]
			td.projectile_speed = t_data["projectile_speed"]
			td.projectile_count = int(t_data["projectile_count"])
			td.spread_angle = t_data["spread_angle"]
			td.piercing = int(t_data["piercing"])
			td.knockback = t_data["knockback"]
			root.tiers.append(td)
		var color: Color = weapon_colors.get(wid, Color(0.5, 0.5, 0.5))
		if w_data["type"] == "melee":
			_build_melee_weapon_visual(root, color)
		else:
			_build_ranged_weapon_visual(root, color)
		_save_scene(root, "res://scenes/content/weapons/%s.tscn" % wid)
		root.free()
	print("  Weapons: %d generated" % json["weapons"].size())

func _build_ranged_weapon_visual(root: Node3D, color: Color) -> void:
	var model := Node3D.new()
	model.name = "Model"

	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = 0.5
	mat.roughness = 0.4

	# Barrel
	var barrel := MeshInstance3D.new()
	barrel.name = "Barrel"
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.06
	cyl.bottom_radius = 0.06
	cyl.height = 0.7
	barrel.mesh = cyl
	barrel.rotation_degrees = Vector3(90, 0, 0)
	barrel.position = Vector3(0, 0.05, -0.35)
	barrel.material_override = mat
	model.add_child(barrel)
	barrel.owner = root

	# Body
	var body := MeshInstance3D.new()
	body.name = "Body"
	var body_mesh := BoxMesh.new()
	body_mesh.size = Vector3(0.18, 0.16, 0.3)
	body.mesh = body_mesh
	body.position = Vector3(0, 0.05, 0.05)
	body.material_override = mat
	model.add_child(body)
	body.owner = root

	# Muzzle flash
	var muzzle := MeshInstance3D.new()
	muzzle.name = "Muzzle"
	var sphere := SphereMesh.new()
	sphere.radius = 0.05
	sphere.height = 0.1
	muzzle.mesh = sphere
	muzzle.position = Vector3(0, 0.05, -0.7)
	var muz_mat := StandardMaterial3D.new()
	muz_mat.albedo_color = Color(1.0, 0.9, 0.3)
	muz_mat.emission_enabled = true
	muz_mat.emission = Color(1.0, 0.8, 0.2)
	muz_mat.emission_energy_multiplier = 3.0
	muzzle.material_override = muz_mat
	model.add_child(muzzle)
	muzzle.owner = root

	root.add_child(model)
	model.owner = root

func _build_melee_weapon_visual(root: Node3D, color: Color) -> void:
	var model := Node3D.new()
	model.name = "Model"

	# Bumper plate
	var plate := MeshInstance3D.new()
	plate.name = "Plate"
	var plate_mesh := BoxMesh.new()
	plate_mesh.size = Vector3(0.7, 0.22, 0.08)
	plate.mesh = plate_mesh
	plate.position = Vector3(0, 0.05, -0.15)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = 0.7
	mat.roughness = 0.3
	plate.material_override = mat
	model.add_child(plate)
	plate.owner = root

	# Impact glow strip
	var glow := MeshInstance3D.new()
	glow.name = "GlowStrip"
	var glow_mesh := BoxMesh.new()
	glow_mesh.size = Vector3(0.65, 0.06, 0.04)
	glow.mesh = glow_mesh
	glow.position = Vector3(0, 0.05, -0.2)
	var glow_mat := StandardMaterial3D.new()
	glow_mat.albedo_color = Color(1.0, 0.5, 0.2)
	glow_mat.emission_enabled = true
	glow_mat.emission = Color(1.0, 0.4, 0.1)
	glow_mat.emission_energy_multiplier = 3.0
	glow.material_override = glow_mat
	model.add_child(glow)
	glow.owner = root

	root.add_child(model)
	model.owner = root

# ─── ITEMS ──────────────────────────────────────────────────

func _generate_items() -> void:
	var json := _load_json("res://data/items.json")
	var category_colors := {
		"defense": Color(0.3, 0.5, 0.9),
		"offense": Color(0.9, 0.3, 0.2),
		"speed": Color(0.2, 0.9, 0.4),
		"utility": Color(0.8, 0.7, 0.2),
		"special": Color(0.9, 0.6, 1.0),
	}
	for item_data: Dictionary in json["items"]:
		var root := ItemScene.new()
		var iid: String = item_data["id"]
		root.id = iid
		root.item_name = item_data["name"]
		root.description = item_data.get("description", "")
		root.rarity = item_data.get("rarity", "common")
		root.base_price = int(item_data.get("base_price", 25))
		root.max_stack = int(item_data.get("max_stack", 10))
		root.category = item_data.get("category", "utility")
		root.stat_modifiers = []
		for mod_data: Dictionary in item_data.get("stat_modifiers", []):
			var smd := StatModifierData.new()
			smd.stat = mod_data["stat"]
			smd.type = mod_data.get("type", "flat")
			smd.value = mod_data["value"]
			root.stat_modifiers.append(smd)
		var color: Color = category_colors.get(root.category, Color(0.5, 0.5, 0.5))
		_build_item_visual(root, color, root.category)
		_save_scene(root, "res://scenes/content/items/%s.tscn" % iid)
		root.free()
	print("  Items: %d generated" % json["items"].size())

func _build_item_visual(root: Node3D, color: Color, category: String) -> void:
	var model := Node3D.new()
	model.name = "Model"
	match category:
		"defense":
			_add_shield_model(model, root, color)
		"offense":
			_add_sword_model(model, root, color)
		"speed":
			_add_bolt_model(model, root, color)
		"special":
			_add_star_model(model, root, color)
		_:
			_add_crystal_model(model, root, color)
	root.add_child(model)
	model.owner = root

func _add_shield_model(model: Node3D, root: Node3D, color: Color) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = 0.7
	mat.roughness = 0.3
	var shield := MeshInstance3D.new()
	shield.name = "Shield"
	var smesh := BoxMesh.new()
	smesh.size = Vector3(0.5, 0.6, 0.08)
	shield.mesh = smesh
	shield.material_override = mat
	model.add_child(shield)
	shield.owner = root
	# Cross detail
	var cross_h := MeshInstance3D.new()
	cross_h.name = "CrossH"
	var ch_mesh := BoxMesh.new()
	ch_mesh.size = Vector3(0.35, 0.06, 0.1)
	cross_h.mesh = ch_mesh
	cross_h.position = Vector3(0, 0.05, 0)
	var gmat := StandardMaterial3D.new()
	gmat.albedo_color = Color(1, 1, 1)
	gmat.emission_enabled = true
	gmat.emission = color
	gmat.emission_energy_multiplier = 2.0
	cross_h.material_override = gmat
	model.add_child(cross_h)
	cross_h.owner = root
	var cross_v := MeshInstance3D.new()
	cross_v.name = "CrossV"
	var cv_mesh := BoxMesh.new()
	cv_mesh.size = Vector3(0.06, 0.4, 0.1)
	cross_v.mesh = cv_mesh
	cross_v.position = Vector3(0, 0, 0)
	cross_v.material_override = gmat
	model.add_child(cross_v)
	cross_v.owner = root

func _add_sword_model(model: Node3D, root: Node3D, color: Color) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = 0.8
	mat.roughness = 0.2
	var blade := MeshInstance3D.new()
	blade.name = "Blade"
	var bmesh := BoxMesh.new()
	bmesh.size = Vector3(0.08, 0.6, 0.04)
	blade.mesh = bmesh
	blade.position = Vector3(0, 0.15, 0)
	blade.material_override = mat
	model.add_child(blade)
	blade.owner = root
	# Guard
	var guard := MeshInstance3D.new()
	guard.name = "Guard"
	var gmesh := BoxMesh.new()
	gmesh.size = Vector3(0.3, 0.06, 0.06)
	guard.mesh = gmesh
	guard.position = Vector3(0, -0.15, 0)
	guard.material_override = mat
	model.add_child(guard)
	guard.owner = root
	# Grip
	var grip := MeshInstance3D.new()
	grip.name = "Grip"
	var grmesh := BoxMesh.new()
	grmesh.size = Vector3(0.06, 0.2, 0.06)
	grip.mesh = grmesh
	grip.position = Vector3(0, -0.28, 0)
	var grip_mat := StandardMaterial3D.new()
	grip_mat.albedo_color = Color(0.3, 0.2, 0.1)
	grip.material_override = grip_mat
	model.add_child(grip)
	grip.owner = root
	# Tip glow
	var tip := MeshInstance3D.new()
	tip.name = "TipGlow"
	var tmesh := SphereMesh.new()
	tmesh.radius = 0.04
	tmesh.height = 0.08
	tip.mesh = tmesh
	tip.position = Vector3(0, 0.45, 0)
	var tmat := StandardMaterial3D.new()
	tmat.emission_enabled = true
	tmat.emission = color
	tmat.emission_energy_multiplier = 3.0
	tip.material_override = tmat
	model.add_child(tip)
	tip.owner = root

func _add_bolt_model(model: Node3D, root: Node3D, color: Color) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 2.0
	var segments := [
		Vector3(0, 0.2, 0), Vector3(0.12, 0.05, 0),
		Vector3(-0.05, -0.1, 0), Vector3(0.08, -0.25, 0),
	]
	for i in segments.size():
		var seg := MeshInstance3D.new()
		seg.name = "Bolt_%d" % i
		var smesh := BoxMesh.new()
		smesh.size = Vector3(0.1, 0.15, 0.06)
		seg.mesh = smesh
		seg.position = segments[i]
		seg.rotation_degrees.z = [-15, 20, -15, 20][i]
		seg.material_override = mat
		model.add_child(seg)
		seg.owner = root
	# Glow sphere
	var glow := MeshInstance3D.new()
	glow.name = "GlowSphere"
	var gmesh := SphereMesh.new()
	gmesh.radius = 0.08
	gmesh.height = 0.16
	glow.mesh = gmesh
	var gmat := StandardMaterial3D.new()
	gmat.emission_enabled = true
	gmat.emission = color
	gmat.emission_energy_multiplier = 4.0
	glow.material_override = gmat
	model.add_child(glow)
	glow.owner = root

func _add_star_model(model: Node3D, root: Node3D, color: Color) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 3.0
	# Central sphere
	var center := MeshInstance3D.new()
	center.name = "Center"
	var cmesh := SphereMesh.new()
	cmesh.radius = 0.12
	cmesh.height = 0.24
	center.mesh = cmesh
	center.material_override = mat
	model.add_child(center)
	center.owner = root
	# Spikes
	for i in 4:
		var spike := MeshInstance3D.new()
		spike.name = "Spike_%d" % i
		var smesh := BoxMesh.new()
		smesh.size = Vector3(0.04, 0.3, 0.04)
		spike.mesh = smesh
		spike.rotation_degrees.z = i * 45.0
		spike.material_override = mat
		model.add_child(spike)
		spike.owner = root

func _add_crystal_model(model: Node3D, root: Node3D, color: Color) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.metallic = 0.5
	mat.roughness = 0.3
	# Rotated box diamond
	var crystal := MeshInstance3D.new()
	crystal.name = "Crystal"
	var cmesh := BoxMesh.new()
	cmesh.size = Vector3(0.3, 0.3, 0.3)
	crystal.mesh = cmesh
	crystal.rotation_degrees = Vector3(45, 0, 45)
	crystal.material_override = mat
	model.add_child(crystal)
	crystal.owner = root
	# Inner glow
	var glow := MeshInstance3D.new()
	glow.name = "InnerGlow"
	var gmesh := SphereMesh.new()
	gmesh.radius = 0.1
	gmesh.height = 0.2
	glow.mesh = gmesh
	var gmat := StandardMaterial3D.new()
	gmat.emission_enabled = true
	gmat.emission = color
	gmat.emission_energy_multiplier = 3.0
	glow.material_override = gmat
	model.add_child(glow)
	glow.owner = root

# ─── UPGRADES ──────────────────────────────────────────────────

func _generate_upgrades() -> void:
	var json := _load_json("res://data/upgrades.json")
	var rarity_colors := {
		"common": Color(0.6, 0.6, 0.7),
		"uncommon": Color(0.2, 0.8, 0.3),
		"rare": Color(0.3, 0.5, 1.0),
		"legendary": Color(1.0, 0.7, 0.1),
	}
	for u_data: Dictionary in json["upgrades"]:
		var root := UpgradeScene.new()
		var uid: String = u_data["id"]
		root.id = uid
		root.upgrade_name = u_data["name"]
		root.description = u_data.get("description", "")
		root.rarity = u_data.get("rarity", "common")
		root.weight = u_data.get("weight", 10.0)
		root.stat_modifiers = []
		for mod_data: Dictionary in u_data.get("stat_modifiers", []):
			var smd := StatModifierData.new()
			smd.stat = mod_data["stat"]
			smd.type = mod_data.get("type", "flat")
			smd.value = mod_data["value"]
			root.stat_modifiers.append(smd)
		var color: Color = rarity_colors.get(root.rarity, Color(0.6, 0.6, 0.7))
		_build_upgrade_visual(root, color)
		_save_scene(root, "res://scenes/content/upgrades/%s.tscn" % uid)
		root.free()
	print("  Upgrades: %d generated" % json["upgrades"].size())

func _build_upgrade_visual(root: Node3D, color: Color) -> void:
	var model := Node3D.new()
	model.name = "Model"
	# Arrow pointing up
	var arrow := MeshInstance3D.new()
	arrow.name = "Arrow"
	var amesh := CylinderMesh.new()
	amesh.top_radius = 0.0
	amesh.bottom_radius = 0.2
	amesh.height = 0.3
	arrow.mesh = amesh
	arrow.position = Vector3(0, 0.25, 0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 2.0
	arrow.material_override = mat
	model.add_child(arrow)
	arrow.owner = root
	# Base cylinder
	var base := MeshInstance3D.new()
	base.name = "Base"
	var bmesh := CylinderMesh.new()
	bmesh.top_radius = 0.12
	bmesh.bottom_radius = 0.12
	bmesh.height = 0.3
	base.mesh = bmesh
	base.position = Vector3(0, -0.05, 0)
	base.material_override = mat
	model.add_child(base)
	base.owner = root
	root.add_child(model)
	model.owner = root

# ─── UTILITIES ──────────────────────────────────────────────────

func _load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	var text := file.get_as_text()
	file.close()
	return JSON.parse_string(text)

func _save_scene(root: Node, path: String) -> void:
	var scene := PackedScene.new()
	scene.pack(root)
	ResourceSaver.save(scene, path)
