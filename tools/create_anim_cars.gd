## Creates two demo cars with extreme roll / pitch animations
## Run with: godot --headless -s tools/create_anim_cars.gd
extends SceneTree

func _init() -> void:
	_create_roller()
	_create_bouncer()
	print("Done! Created car_roller.tscn and car_bouncer.tscn")
	quit()

# ── Roller: extreme body roll, leans hard into every turn ──
func _create_roller() -> void:
	var root := CarScene.new()
	root.id = "car_roller"
	root.car_name = "Tilt Master"
	root.unlock_condition = "none"
	# Balanced stats, slightly drifty
	root.max_hp = 90.0
	root.hp_regen = 1.0
	root.armor = 0.0
	root.max_speed = 30.0
	root.boost_speed = 48.0
	root.base_accel = 36.0
	root.friction = 0.98
	root.normal_grip = 0.13
	root.drift_grip = 0.015
	root.turn_speed_normal = 9.0
	root.turn_speed_drift = 13.0
	root.charge_rate = 55.0
	root.max_charge = 100.0
	root.boost_duration = 1.6
	root.nitro_max = 110.0
	root.nitro_accumulation_rate = 12.0
	root.nitro_drain_rate = 28.0
	root.nitro_damage = 35.0
	root.weapon_slots = 4
	# Extreme roll animation
	root.roll_normal = 0.45       # 3x default (0.15)
	root.roll_drift = 0.80        # 2.7x default (0.30)
	root.roll_lerp_speed = 12.0   # Snappy response
	root.pitch_accel = -0.04
	root.pitch_boost = -0.08
	root.pitch_idle = 0.02
	root.pitch_lerp_speed = 5.0

	_build_car(root, Color(1.0, 0.4, 0.0))  # Orange
	_save(root, "res://scenes/content/cars/car_roller.tscn")
	print("  car_roller.tscn (Tilt Master) created")

# ── Bouncer: extreme pitch, nose dives and rears up dramatically ──
func _create_bouncer() -> void:
	var root := CarScene.new()
	root.id = "car_bouncer"
	root.car_name = "Nose Diver"
	root.unlock_condition = "none"
	# Heavy, powerful, slow turn
	root.max_hp = 120.0
	root.hp_regen = 1.5
	root.armor = 2.0
	root.max_speed = 26.0
	root.boost_speed = 44.0
	root.base_accel = 40.0
	root.friction = 0.975
	root.normal_grip = 0.16
	root.drift_grip = 0.025
	root.turn_speed_normal = 7.0
	root.turn_speed_drift = 10.0
	root.charge_rate = 45.0
	root.max_charge = 100.0
	root.boost_duration = 1.3
	root.nitro_max = 90.0
	root.nitro_accumulation_rate = 9.0
	root.nitro_drain_rate = 22.0
	root.nitro_damage = 45.0
	root.weapon_slots = 4
	# Extreme pitch animation
	root.roll_normal = 0.12
	root.roll_drift = 0.25
	root.roll_lerp_speed = 7.0
	root.pitch_accel = -0.20      # 4x default — heavy nose dive on gas
	root.pitch_boost = -0.40      # 3.3x default — massive dive on boost
	root.pitch_idle = 0.12        # 4x default — rears up when coasting
	root.pitch_lerp_speed = 10.0  # Fast response for bouncy feel

	_build_car(root, Color(0.2, 0.7, 0.1))  # Green
	_save(root, "res://scenes/content/cars/car_bouncer.tscn")
	print("  car_bouncer.tscn (Nose Diver) created")

# ── Shared car visual builder ──
func _build_car(root: Node3D, body_color: Color) -> void:
	var body_wrap := Node3D.new()
	body_wrap.name = "BodyWrap"
	var chassis := MeshInstance3D.new()
	chassis.name = "Chassis"
	var cm := BoxMesh.new()
	cm.size = Vector3(1.8, 0.5, 2.8)
	chassis.mesh = cm
	chassis.position = Vector3(0, 0.35, 0)
	var cmat := StandardMaterial3D.new()
	cmat.albedo_color = body_color
	cmat.metallic = 0.6
	cmat.roughness = 0.3
	chassis.material_override = cmat
	body_wrap.add_child(chassis)
	var cabin := MeshInstance3D.new()
	cabin.name = "Cabin"
	var cbm := BoxMesh.new()
	cbm.size = Vector3(1.4, 0.4, 1.4)
	cabin.mesh = cbm
	cabin.position = Vector3(0, 0.75, 0.15)
	var cabin_mat := StandardMaterial3D.new()
	cabin_mat.albedo_color = Color(0.3, 0.7, 1.0, 0.8)
	cabin_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	cabin_mat.metallic = 0.8
	cabin_mat.roughness = 0.1
	cabin.material_override = cabin_mat
	body_wrap.add_child(cabin)
	var hl_mat := StandardMaterial3D.new()
	hl_mat.albedo_color = Color(1, 1, 0.8)
	hl_mat.emission_enabled = true
	hl_mat.emission = Color(1, 1, 0.8)
	hl_mat.emission_energy_multiplier = 3.0
	for si in 2:
		var sx := -0.65 if si == 0 else 0.65
		var hl := MeshInstance3D.new()
		hl.name = "HeadlightL" if si == 0 else "HeadlightR"
		var hm := BoxMesh.new()
		hm.size = Vector3(0.3, 0.15, 0.1)
		hl.mesh = hm
		hl.position = Vector3(sx, 0.45, -1.45)
		hl.material_override = hl_mat
		body_wrap.add_child(hl)
	var tl_mat := StandardMaterial3D.new()
	tl_mat.albedo_color = Color(1, 0.1, 0.1)
	tl_mat.emission_enabled = true
	tl_mat.emission = Color(1, 0.1, 0.1)
	tl_mat.emission_energy_multiplier = 2.0
	for si in 2:
		var sx := -0.7 if si == 0 else 0.7
		var tl := MeshInstance3D.new()
		tl.name = "TaillightL" if si == 0 else "TaillightR"
		var tm := BoxMesh.new()
		tm.size = Vector3(0.25, 0.12, 0.08)
		tl.mesh = tm
		tl.position = Vector3(sx, 0.4, 1.45)
		tl.material_override = tl_mat
		body_wrap.add_child(tl)
	root.add_child(body_wrap)
	var wmat := StandardMaterial3D.new()
	wmat.albedo_color = Color(0.15, 0.15, 0.15)
	wmat.roughness = 0.9
	var wpos := [Vector3(-1,0.2,-0.9), Vector3(1,0.2,-0.9), Vector3(-1,0.2,0.9), Vector3(1,0.2,0.9)]
	var wnames := ["WheelFL","WheelFR","WheelRL","WheelRR"]
	for i in 4:
		var w := MeshInstance3D.new()
		w.name = wnames[i]
		var c := CylinderMesh.new()
		c.top_radius = 0.25; c.bottom_radius = 0.25; c.height = 0.2
		w.mesh = c; w.position = wpos[i]; w.rotation_degrees = Vector3(0,0,90)
		w.material_override = wmat
		root.add_child(w)
	for pi in 2:
		var px := -0.5 if pi == 0 else 0.5
		var ex := GPUParticles3D.new()
		ex.name = "BoostExhaustL" if pi == 0 else "BoostExhaustR"
		ex.emitting = false; ex.amount = 60; ex.lifetime = 0.5; ex.speed_scale = 1.5
		ex.visibility_aabb = AABB(Vector3(-5,-2,-5), Vector3(10,5,10))
		var em := ParticleProcessMaterial.new()
		em.direction = Vector3(0,0.3,1); em.spread = 12.0
		em.initial_velocity_min = 12.0; em.initial_velocity_max = 22.0
		em.gravity = Vector3(0,3,0); em.scale_min = 0.3; em.scale_max = 0.8
		em.color = Color(1,0.5,0.1)
		ex.process_material = em
		var edm := StandardMaterial3D.new()
		edm.albedo_color = Color(1,0.6,0.1); edm.emission_enabled = true
		edm.emission = Color(1,0.4,0.05); edm.emission_energy_multiplier = 5.0
		edm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		edm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		var eq := QuadMesh.new(); eq.size = Vector2(0.5,0.5); eq.material = edm
		ex.draw_pass_1 = eq; ex.position = Vector3(px, 0.25, 1.5)
		root.add_child(ex)
	for si in 2:
		var sx := -0.9 if si == 0 else 0.9
		var sp := GPUParticles3D.new()
		sp.name = "DriftSparksL" if si == 0 else "DriftSparksR"
		sp.emitting = false; sp.amount = 30; sp.lifetime = 0.35
		sp.visibility_aabb = AABB(Vector3(-4,-2,-4), Vector3(8,5,8))
		var sm := ParticleProcessMaterial.new()
		sm.direction = Vector3(0,1,0); sm.spread = 50.0
		sm.initial_velocity_min = 4.0; sm.initial_velocity_max = 10.0
		sm.gravity = Vector3(0,-20,0); sm.scale_min = 0.04; sm.scale_max = 0.12
		sm.color = Color(1,0.7,0.2)
		sp.process_material = sm
		var sdm := StandardMaterial3D.new()
		sdm.emission_enabled = true; sdm.emission = Color(1,0.7,0.2)
		sdm.emission_energy_multiplier = 4.0; sdm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		var sq := QuadMesh.new(); sq.size = Vector2(0.08,0.08); sq.material = sdm
		sp.draw_pass_1 = sq; sp.position = Vector3(sx, 0.1, 0.9)
		root.add_child(sp)

func _save(root: Node, path: String) -> void:
	_own(root, root)
	var s := PackedScene.new(); s.pack(root)
	ResourceSaver.save(s, path); root.free()

func _own(node: Node, o: Node) -> void:
	for c in node.get_children(): c.owner = o; _own(c, o)
