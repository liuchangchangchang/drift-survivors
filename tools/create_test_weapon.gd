## One-off script to create a new test weapon: Plasma Launcher
## Run with: godot --headless -s tools/create_test_weapon.gd
extends SceneTree

func _init() -> void:
	var root := WeaponScene.new()
	root.id = "weapon_plasma"
	root.weapon_name = "Plasma Launcher"
	root.type = "ranged"
	root.damage_type = "elemental"
	root.can_be_starting_weapon = true

	# Slow fire, high damage, AOE-style (multi-projectile with spread)
	var t1 := WeaponTierData.new()
	t1.tier = 1; t1.damage = 18.0; t1.fire_rate = 1.2
	t1.weapon_range = 18.0; t1.projectile_speed = 20.0
	t1.projectile_count = 1; t1.spread_angle = 0.0
	t1.piercing = 1; t1.knockback = 2.0

	var t2 := WeaponTierData.new()
	t2.tier = 2; t2.damage = 30.0; t2.fire_rate = 1.0
	t2.weapon_range = 20.0; t2.projectile_speed = 22.0
	t2.projectile_count = 1; t2.spread_angle = 0.0
	t2.piercing = 2; t2.knockback = 2.5

	var t3 := WeaponTierData.new()
	t3.tier = 3; t3.damage = 45.0; t3.fire_rate = 0.85
	t3.weapon_range = 22.0; t3.projectile_speed = 24.0
	t3.projectile_count = 2; t3.spread_angle = 10.0
	t3.piercing = 3; t3.knockback = 3.0

	var t4 := WeaponTierData.new()
	t4.tier = 4; t4.damage = 70.0; t4.fire_rate = 0.7
	t4.weapon_range = 25.0; t4.projectile_speed = 26.0
	t4.projectile_count = 3; t4.spread_angle = 15.0
	t4.piercing = 5; t4.knockback = 4.0

	root.tiers = [t1, t2, t3, t4]

	_build_visual(root)
	_set_owner_recursive(root, root)

	var scene := PackedScene.new()
	scene.pack(root)
	ResourceSaver.save(scene, "res://scenes/content/weapons/weapon_plasma.tscn")
	root.free()
	print("weapon_plasma.tscn created!")
	quit()

func _build_visual(root: Node3D) -> void:
	var color := Color(0.1, 0.8, 0.9)

	var model := Node3D.new()
	model.name = "Model"

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.15, 0.2, 0.25)
	mat.metallic = 0.6
	mat.roughness = 0.3

	# Wide barrel (shorter, fatter than pistol)
	var barrel := MeshInstance3D.new()
	barrel.name = "Barrel"
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.1
	cyl.bottom_radius = 0.12
	cyl.height = 0.5
	barrel.mesh = cyl
	barrel.rotation_degrees = Vector3(90, 0, 0)
	barrel.position = Vector3(0, 0.05, -0.25)
	barrel.material_override = mat
	model.add_child(barrel)

	# Chunky body / energy chamber
	var body := MeshInstance3D.new()
	body.name = "Body"
	var body_mesh := BoxMesh.new()
	body_mesh.size = Vector3(0.22, 0.2, 0.35)
	body.mesh = body_mesh
	body.position = Vector3(0, 0.05, 0.1)
	body.material_override = mat
	model.add_child(body)

	# Plasma core (glowing sphere inside body)
	var core := MeshInstance3D.new()
	core.name = "PlasmaCore"
	var core_mesh := SphereMesh.new()
	core_mesh.radius = 0.08
	core_mesh.height = 0.16
	core.mesh = core_mesh
	core.position = Vector3(0, 0.05, 0.1)
	var core_mat := StandardMaterial3D.new()
	core_mat.albedo_color = color
	core_mat.emission_enabled = true
	core_mat.emission = color
	core_mat.emission_energy_multiplier = 5.0
	core.material_override = core_mat
	model.add_child(core)

	# Muzzle ring (torus-like using a thin cylinder)
	var muzzle := MeshInstance3D.new()
	muzzle.name = "MuzzleRing"
	var ring := CylinderMesh.new()
	ring.top_radius = 0.11
	ring.bottom_radius = 0.11
	ring.height = 0.03
	muzzle.mesh = ring
	muzzle.rotation_degrees = Vector3(90, 0, 0)
	muzzle.position = Vector3(0, 0.05, -0.5)
	var ring_mat := StandardMaterial3D.new()
	ring_mat.albedo_color = color
	ring_mat.emission_enabled = true
	ring_mat.emission = color
	ring_mat.emission_energy_multiplier = 3.0
	muzzle.material_override = ring_mat
	model.add_child(muzzle)

	root.add_child(model)

func _set_owner_recursive(node: Node, owner_node: Node) -> void:
	for child in node.get_children():
		child.owner = owner_node
		_set_owner_recursive(child, owner_node)
