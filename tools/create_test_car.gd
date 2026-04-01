## One-off script to create a new test car: Shadow Racer
## Run with: godot --headless -s tools/create_test_car.gd
extends SceneTree

func _init() -> void:
	var root := CarScene.new()
	root.id = "car_shadow"
	root.car_name = "Shadow Racer"
	root.unlock_condition = "none"
	# Glass cannon: fast, fragile, extreme drift
	root.max_hp = 60.0
	root.hp_regen = 0.5
	root.armor = 0.0
	root.max_speed = 33.0
	root.boost_speed = 52.0
	root.base_accel = 40.0
	root.friction = 0.99
	root.normal_grip = 0.10
	root.drift_grip = 0.008
	root.turn_speed_normal = 11.0
	root.turn_speed_drift = 16.0
	root.charge_rate = 80.0
	root.max_charge = 100.0
	root.boost_duration = 2.2
	root.nitro_max = 180.0
	root.nitro_accumulation_rate = 25.0
	root.nitro_drain_rate = 40.0
	root.nitro_damage = 45.0
	root.weapon_slots = 3

	_build_visual(root)
	_set_owner_recursive(root, root)

	var scene := PackedScene.new()
	scene.pack(root)
	ResourceSaver.save(scene, "res://scenes/content/cars/car_shadow.tscn")
	root.free()
	print("car_shadow.tscn created!")
	quit()

func _build_visual(root: Node3D) -> void:
	var body_color := Color(0.25, 0.05, 0.35)  # Dark purple

	var body_wrap := Node3D.new()
	body_wrap.name = "BodyWrap"

	# Chassis - sleeker, lower profile
	var chassis := MeshInstance3D.new()
	chassis.name = "Chassis"
	var chassis_mesh := BoxMesh.new()
	chassis_mesh.size = Vector3(1.6, 0.4, 3.0)
	chassis.mesh = chassis_mesh
	chassis.position = Vector3(0, 0.3, 0)
	var chassis_mat := StandardMaterial3D.new()
	chassis_mat.albedo_color = body_color
	chassis_mat.metallic = 0.8
	chassis_mat.roughness = 0.15
	chassis_mat.emission_enabled = true
	chassis_mat.emission = Color(0.4, 0.1, 0.6)
	chassis_mat.emission_energy_multiplier = 0.3
	chassis.material_override = chassis_mat
	body_wrap.add_child(chassis)

	# Cabin - tinted dark purple
	var cabin := MeshInstance3D.new()
	cabin.name = "Cabin"
	var cabin_mesh := BoxMesh.new()
	cabin_mesh.size = Vector3(1.2, 0.35, 1.2)
	cabin.mesh = cabin_mesh
	cabin.position = Vector3(0, 0.65, 0.2)
	var cabin_mat := StandardMaterial3D.new()
	cabin_mat.albedo_color = Color(0.2, 0.0, 0.3, 0.7)
	cabin_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	cabin_mat.metallic = 0.9
	cabin_mat.roughness = 0.05
	cabin.material_override = cabin_mat
	body_wrap.add_child(cabin)

	# Headlights - purple glow
	var hl_mat := StandardMaterial3D.new()
	hl_mat.albedo_color = Color(0.7, 0.3, 1.0)
	hl_mat.emission_enabled = true
	hl_mat.emission = Color(0.6, 0.2, 1.0)
	hl_mat.emission_energy_multiplier = 4.0
	for side_i in 2:
		var side_x := -0.55 if side_i == 0 else 0.55
		var hl := MeshInstance3D.new()
		hl.name = "HeadlightL" if side_i == 0 else "HeadlightR"
		var hl_mesh := BoxMesh.new()
		hl_mesh.size = Vector3(0.25, 0.1, 0.08)
		hl.mesh = hl_mesh
		hl.position = Vector3(side_x, 0.38, -1.55)
		hl.material_override = hl_mat
		body_wrap.add_child(hl)

	# Taillights - purple-pink
	var tl_mat := StandardMaterial3D.new()
	tl_mat.albedo_color = Color(0.8, 0.1, 0.6)
	tl_mat.emission_enabled = true
	tl_mat.emission = Color(0.8, 0.1, 0.6)
	tl_mat.emission_energy_multiplier = 3.0
	for side_i in 2:
		var side_x := -0.6 if side_i == 0 else 0.6
		var tl := MeshInstance3D.new()
		tl.name = "TaillightL" if side_i == 0 else "TaillightR"
		var tl_mesh := BoxMesh.new()
		tl_mesh.size = Vector3(0.2, 0.1, 0.06)
		tl.mesh = tl_mesh
		tl.position = Vector3(side_x, 0.35, 1.55)
		tl.material_override = tl_mat
		body_wrap.add_child(tl)

	# Underglow strip (unique to shadow racer)
	var underglow := MeshInstance3D.new()
	underglow.name = "Underglow"
	var ug_mesh := BoxMesh.new()
	ug_mesh.size = Vector3(1.4, 0.03, 2.6)
	underglow.mesh = ug_mesh
	underglow.position = Vector3(0, 0.08, 0)
	var ug_mat := StandardMaterial3D.new()
	ug_mat.albedo_color = Color(0.5, 0.0, 1.0, 0.6)
	ug_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ug_mat.emission_enabled = true
	ug_mat.emission = Color(0.5, 0.0, 1.0)
	ug_mat.emission_energy_multiplier = 5.0
	underglow.material_override = ug_mat
	body_wrap.add_child(underglow)

	root.add_child(body_wrap)

	# Wheels - dark chrome
	var wheel_mat := StandardMaterial3D.new()
	wheel_mat.albedo_color = Color(0.1, 0.05, 0.15)
	wheel_mat.metallic = 0.8
	wheel_mat.roughness = 0.3
	var wheel_positions := [
		Vector3(-0.9, 0.18, -1.0),
		Vector3(0.9, 0.18, -1.0),
		Vector3(-0.9, 0.18, 1.0),
		Vector3(0.9, 0.18, 1.0),
	]
	var wheel_names := ["WheelFL", "WheelFR", "WheelRL", "WheelRR"]
	for i in wheel_positions.size():
		var wheel := MeshInstance3D.new()
		wheel.name = wheel_names[i]
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.22
		cyl.bottom_radius = 0.22
		cyl.height = 0.18
		wheel.mesh = cyl
		wheel.position = wheel_positions[i]
		wheel.rotation_degrees = Vector3(0, 0, 90)
		wheel.material_override = wheel_mat
		root.add_child(wheel)

	# Boost exhaust - purple flames
	for pipe_i in 2:
		var pipe_x := -0.4 if pipe_i == 0 else 0.4
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
		ex_mat.color = Color(0.6, 0.1, 1.0)
		exhaust.process_material = ex_mat
		var ex_draw_mat := StandardMaterial3D.new()
		ex_draw_mat.albedo_color = Color(0.7, 0.2, 1.0)
		ex_draw_mat.emission_enabled = true
		ex_draw_mat.emission = Color(0.5, 0.0, 0.8)
		ex_draw_mat.emission_energy_multiplier = 5.0
		ex_draw_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		ex_draw_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		var ex_draw := QuadMesh.new()
		ex_draw.size = Vector2(0.5, 0.5)
		ex_draw.material = ex_draw_mat
		exhaust.draw_pass_1 = ex_draw
		exhaust.position = Vector3(pipe_x, 0.2, 1.6)
		root.add_child(exhaust)

	# Drift sparks
	for spark_i in 2:
		var spark_x := -0.85 if spark_i == 0 else 0.85
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
		sp_mat.color = Color(0.6, 0.3, 1.0)
		sparks.process_material = sp_mat
		var sp_draw_mat := StandardMaterial3D.new()
		sp_draw_mat.emission_enabled = true
		sp_draw_mat.emission = Color(0.6, 0.3, 1.0)
		sp_draw_mat.emission_energy_multiplier = 4.0
		sp_draw_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		var sp_draw := QuadMesh.new()
		sp_draw.size = Vector2(0.08, 0.08)
		sp_draw.material = sp_draw_mat
		sparks.draw_pass_1 = sp_draw
		sparks.position = Vector3(spark_x, 0.1, 1.0)
		root.add_child(sparks)

func _set_owner_recursive(node: Node, owner_node: Node) -> void:
	for child in node.get_children():
		child.owner = owner_node
		_set_owner_recursive(child, owner_node)
