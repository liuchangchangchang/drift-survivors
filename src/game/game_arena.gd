extends Node3D
## Main 3D gameplay arena. Wires all systems together.

var car: CarController
var wave_manager: WaveManager
var enemy_spawner: EnemySpawner
var loot_spawner: LootSpawner
var weapon_mount_mgr: WeaponMountManager
var level_up_mgr: LevelUpManager
var camera: CameraController

var economy: EconomyManager
var inventory: Inventory
var player_stats: PlayerStats
var shop_manager: ShopManager

var hud_node: Node
var shop_ui: Control
var level_up_ui: Control
var pause_menu: Control
var game_over_ui: Control
var victory_ui: Control

var selected_car_id: String = "car_starter"
var selected_weapon_id: String = "weapon_pistol"

const ARENA_SIZE: float = 150.0

func _ready() -> void:
	_create_environment()
	_create_ground()
	_setup_systems()
	_setup_ui()
	_connect_signals()
	_start_first_wave()

func _create_environment() -> void:
	# Main directional light
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-55, -35, 0)
	light.light_energy = 1.0
	light.light_color = Color(1.0, 0.95, 0.9)
	light.shadow_enabled = true
	light.shadow_blur = 1.5
	add_child(light)
	# Fill light (softer, opposite direction)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-30, 145, 0)
	fill.light_energy = 0.3
	fill.light_color = Color(0.7, 0.8, 1.0)
	fill.shadow_enabled = false
	add_child(fill)
	# World environment
	var env_node := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.02, 0.02, 0.06)
	environment.ambient_light_color = Color(0.25, 0.3, 0.4)
	environment.ambient_light_energy = 0.5
	environment.glow_enabled = true
	environment.glow_intensity = 0.4
	environment.glow_bloom = 0.1
	env_node.environment = environment
	add_child(env_node)

func _create_ground() -> void:
	# Ground plane - dark asphalt look
	var ground := MeshInstance3D.new()
	var plane_mesh := PlaneMesh.new()
	plane_mesh.size = Vector2(ARENA_SIZE, ARENA_SIZE)
	ground.mesh = plane_mesh
	ground.position = Vector3(ARENA_SIZE / 2, 0, ARENA_SIZE / 2)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.12, 0.13, 0.16)
	mat.roughness = 0.95
	mat.metallic = 0.0
	ground.material_override = mat
	add_child(ground)
	# Sparse grid lines (every 15 units) for orientation
	var grid_mat := StandardMaterial3D.new()
	grid_mat.albedo_color = Color(0.18, 0.19, 0.23)
	grid_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for i in range(0, int(ARENA_SIZE) + 1, 15):
		var vline := MeshInstance3D.new()
		var vbox := BoxMesh.new()
		vbox.size = Vector3(0.04, 0.005, ARENA_SIZE)
		vline.mesh = vbox
		vline.position = Vector3(i, 0.005, ARENA_SIZE / 2)
		vline.material_override = grid_mat
		add_child(vline)
		var hline := MeshInstance3D.new()
		var hbox := BoxMesh.new()
		hbox.size = Vector3(ARENA_SIZE, 0.005, 0.04)
		hline.mesh = hbox
		hline.position = Vector3(ARENA_SIZE / 2, 0.005, i)
		hline.material_override = grid_mat
		add_child(hline)

func _setup_systems() -> void:
	economy = EconomyManager.new()
	economy.name = "EconomyManager"
	add_child(economy)

	inventory = Inventory.new()

	player_stats = PlayerStats.new()
	player_stats.name = "PlayerStats"
	add_child(player_stats)

	var car_data := DataLoader.get_car_data(selected_car_id)
	var base_stats: Dictionary = car_data.get("base_stats", {})
	player_stats.set_base_stats(base_stats)

	shop_manager = ShopManager.new()

	_create_car(base_stats)

	var starting_weapon := WeaponFactory.create_weapon(selected_weapon_id, 1)
	if starting_weapon:
		weapon_mount_mgr.equip_weapon(starting_weapon)

	enemy_spawner = EnemySpawner.new()
	enemy_spawner.player = car
	enemy_spawner.name = "EnemySpawner"
	add_child(enemy_spawner)

	loot_spawner = LootSpawner.new()
	loot_spawner.name = "LootSpawner"
	add_child(loot_spawner)

	wave_manager = WaveManager.new()
	wave_manager.spawner = enemy_spawner
	wave_manager.player = car
	wave_manager.name = "WaveManager"
	add_child(wave_manager)

	level_up_mgr = LevelUpManager.new()
	level_up_mgr.name = "LevelUpManager"
	add_child(level_up_mgr)

	var proj_mover := ProjectileMover.new()
	proj_mover.name = "ProjectileMover"
	add_child(proj_mover)

	_create_boundaries()

func _create_car(base_stats: Dictionary) -> void:
	car = CarController.new()
	car.stats = CarStats.from_dict(base_stats)
	car.name = "Car"
	car.position = Vector3(ARENA_SIZE / 2, 0, ARENA_SIZE / 2)
	car.collision_layer = 1
	car.collision_mask = 2 | 16 | 32

	# Collision shape
	var car_collision := CollisionShape3D.new()
	var car_shape := BoxShape3D.new()
	car_shape.size = Vector3(2.0, 0.8, 3.0)
	car_collision.shape = car_shape
	car_collision.position = Vector3(0, 0.5, 0)
	car.add_child(car_collision)

	# Visuals node (rotates based on visual_angle)
	var visuals := Node3D.new()
	visuals.name = "Visuals"

	# Body wrap (for roll/pitch effects)
	var body_wrap := Node3D.new()
	body_wrap.name = "BodyWrap"

	# --- Car body (chassis) ---
	var chassis := MeshInstance3D.new()
	var chassis_mesh := BoxMesh.new()
	chassis_mesh.size = Vector3(1.8, 0.5, 2.8)
	chassis.mesh = chassis_mesh
	chassis.position = Vector3(0, 0.35, 0)
	var chassis_mat := StandardMaterial3D.new()
	chassis_mat.albedo_color = Color(0.15, 0.5, 0.95)
	chassis_mat.metallic = 0.6
	chassis_mat.roughness = 0.3
	chassis.material_override = chassis_mat
	body_wrap.add_child(chassis)

	# --- Cabin (top part) ---
	var cabin := MeshInstance3D.new()
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

	# --- Headlights (front) ---
	var hl_mat := StandardMaterial3D.new()
	hl_mat.albedo_color = Color(1.0, 1.0, 0.8)
	hl_mat.emission_enabled = true
	hl_mat.emission = Color(1.0, 1.0, 0.8)
	hl_mat.emission_energy_multiplier = 3.0
	for side in [-0.65, 0.65]:
		var hl := MeshInstance3D.new()
		var hl_mesh := BoxMesh.new()
		hl_mesh.size = Vector3(0.3, 0.15, 0.1)
		hl.mesh = hl_mesh
		hl.position = Vector3(side, 0.45, -1.45)
		hl.material_override = hl_mat
		body_wrap.add_child(hl)

	# --- Taillights (rear) ---
	var tl_mat := StandardMaterial3D.new()
	tl_mat.albedo_color = Color(1.0, 0.1, 0.1)
	tl_mat.emission_enabled = true
	tl_mat.emission = Color(1.0, 0.1, 0.1)
	tl_mat.emission_energy_multiplier = 2.0
	for side in [-0.7, 0.7]:
		var tl := MeshInstance3D.new()
		var tl_mesh := BoxMesh.new()
		tl_mesh.size = Vector3(0.25, 0.12, 0.08)
		tl.mesh = tl_mesh
		tl.position = Vector3(side, 0.4, 1.45)
		tl.material_override = tl_mat
		body_wrap.add_child(tl)

	visuals.add_child(body_wrap)

	# --- Wheels (4 cylinders) ---
	var wheel_mat := StandardMaterial3D.new()
	wheel_mat.albedo_color = Color(0.15, 0.15, 0.15)
	wheel_mat.roughness = 0.9
	var wheel_positions := [
		Vector3(-1.0, 0.2, -0.9),  # FL
		Vector3(1.0, 0.2, -0.9),   # FR
		Vector3(-1.0, 0.2, 0.9),   # RL
		Vector3(1.0, 0.2, 0.9),    # RR
	]
	for i in wheel_positions.size():
		var wheel := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.25
		cyl.bottom_radius = 0.25
		cyl.height = 0.2
		wheel.mesh = cyl
		wheel.position = wheel_positions[i]
		wheel.rotation_degrees = Vector3(0, 0, 90)
		wheel.material_override = wheel_mat
		wheel.name = "Wheel_%d" % i
		visuals.add_child(wheel)

	# --- Boost exhaust particles (rear) ---
	var exhaust := GPUParticles3D.new()
	exhaust.name = "BoostExhaust"
	exhaust.emitting = false
	exhaust.amount = 30
	exhaust.lifetime = 0.4
	exhaust.visibility_aabb = AABB(Vector3(-2, -1, -2), Vector3(4, 3, 4))
	var exhaust_mat := ParticleProcessMaterial.new()
	exhaust_mat.direction = Vector3(0, 0, 1)
	exhaust_mat.spread = 15.0
	exhaust_mat.initial_velocity_min = 8.0
	exhaust_mat.initial_velocity_max = 15.0
	exhaust_mat.gravity = Vector3(0, 2, 0)
	exhaust_mat.scale_min = 0.2
	exhaust_mat.scale_max = 0.5
	exhaust_mat.color = Color(0.2, 0.6, 1.0)
	exhaust.process_material = exhaust_mat
	# Particle mesh
	var exhaust_draw := QuadMesh.new()
	exhaust_draw.size = Vector2(0.3, 0.3)
	exhaust.draw_pass_1 = exhaust_draw
	exhaust.position = Vector3(0, 0.3, 1.5)
	visuals.add_child(exhaust)

	# --- Drift sparks particles ---
	var sparks := GPUParticles3D.new()
	sparks.name = "DriftSparks"
	sparks.emitting = false
	sparks.amount = 20
	sparks.lifetime = 0.3
	sparks.visibility_aabb = AABB(Vector3(-3, -1, -3), Vector3(6, 3, 6))
	var spark_mat := ParticleProcessMaterial.new()
	spark_mat.direction = Vector3(0, 1, 0)
	spark_mat.spread = 60.0
	spark_mat.initial_velocity_min = 3.0
	spark_mat.initial_velocity_max = 8.0
	spark_mat.gravity = Vector3(0, -15, 0)
	spark_mat.scale_min = 0.05
	spark_mat.scale_max = 0.15
	spark_mat.color = Color(1.0, 0.7, 0.2)
	sparks.process_material = spark_mat
	var spark_draw := QuadMesh.new()
	spark_draw.size = Vector2(0.1, 0.1)
	sparks.draw_pass_1 = spark_draw
	sparks.position = Vector3(0, 0.15, 0.8)
	visuals.add_child(sparks)

	car.add_child(visuals)

	# --- Skidmark system ---
	var skidmarks := SkidmarkSystem.new()
	skidmarks.name = "SkidmarkSystem"
	car.add_child(skidmarks)

	# Weapon mount manager
	weapon_mount_mgr = WeaponMountManager.new()
	weapon_mount_mgr.max_slots = int(base_stats.get("weapon_slots", 4))
	weapon_mount_mgr.name = "WeaponMountManager"
	car.add_child(weapon_mount_mgr)

	# Loot magnet
	var magnet := LootMagnet.new()
	magnet.name = "LootMagnet"
	magnet.collision_layer = 0
	magnet.collision_mask = 16
	car.add_child(magnet)

	add_child(car)

	# Camera (independent)
	camera = CameraController.new()
	camera.name = "GameCamera"
	camera.target = car
	add_child(camera)

func _setup_ui() -> void:
	var hud_scene := load("res://scenes/game/hud.tscn")
	if hud_scene:
		hud_node = hud_scene.instantiate()
		add_child(hud_node)

	var shop_scene := load("res://scenes/ui/shop_screen.tscn")
	if shop_scene:
		shop_ui = shop_scene.instantiate()
		shop_ui.visible = false
		shop_ui.shop_closed.connect(_on_shop_closed)
		add_child(shop_ui)

	var lu_scene := load("res://scenes/ui/level_up_screen.tscn")
	if lu_scene:
		level_up_ui = lu_scene.instantiate()
		level_up_ui.visible = false
		level_up_ui.upgrade_selected.connect(_on_upgrade_selected)
		add_child(level_up_ui)

	var pause_scene := load("res://scenes/ui/pause_menu.tscn")
	if pause_scene:
		pause_menu = pause_scene.instantiate()
		add_child(pause_menu)

	var go_scene := load("res://scenes/ui/game_over.tscn")
	if go_scene:
		game_over_ui = go_scene.instantiate()
		add_child(game_over_ui)

	var vic_scene := load("res://scenes/ui/victory_screen.tscn")
	if vic_scene:
		victory_ui = vic_scene.instantiate()
		add_child(victory_ui)

func _connect_signals() -> void:
	EventBus.car_died.connect(_on_car_died)
	EventBus.enemy_killed.connect(enemy_spawner.on_enemy_killed)
	EventBus.material_collected.connect(func(amount: int): economy.add_materials(amount))
	wave_manager.wave_completed.connect(_on_wave_completed)
	level_up_mgr.level_up_ready.connect(_on_level_up)

func _start_first_wave() -> void:
	wave_manager.start_wave(GameManager.current_wave)

func _physics_process(delta: float) -> void:
	if not car or not car.is_alive:
		return
	# HP regen
	var regen := player_stats.get_stat("hp_regen", 1.0)
	if regen > 0:
		car.heal(regen * delta)
	# Update HUD
	if hud_node and hud_node.has_method("update_hp"):
		hud_node.update_hp(car.current_hp, car.stats.max_hp)
		hud_node.update_speed(car.get_speed_normalized())
	if hud_node and hud_node.has_method("update_xp"):
		hud_node.update_xp(level_up_mgr.get_xp_progress())

func _process(delta: float) -> void:
	if not car or not car.is_alive:
		return
	var visuals := car.get_node_or_null("Visuals")
	if not visuals:
		return

	# --- Yaw: rotate visuals to match visual_angle ---
	var target_yaw := -car.visual_angle + PI / 2
	visuals.rotation.y = lerp_angle(visuals.rotation.y, target_yaw, 15.0 * delta)

	# --- Body roll (lean into turns) ---
	var body_wrap := visuals.get_node_or_null("BodyWrap")
	if body_wrap:
		var vel_angle := atan2(car.velocity.z, car.velocity.x)
		var cross := cos(car.visual_angle) * sin(vel_angle) - sin(car.visual_angle) * cos(vel_angle)
		var roll_amount := 0.3 if car.is_drifting else 0.15
		var target_roll := cross * roll_amount
		body_wrap.rotation.z = lerpf(body_wrap.rotation.z, target_roll, 8.0 * delta)
		# Pitch: nose down when accelerating
		var accel_input := Input.get_vector("move_left", "move_right", "move_up", "move_down").length()
		var target_pitch := -0.05 if accel_input > 0.1 else 0.03
		if car.boost_power > 0:
			target_pitch = -0.12
		body_wrap.rotation.x = lerpf(body_wrap.rotation.x, target_pitch, 6.0 * delta)

	# --- Boost exhaust particles ---
	var exhaust := visuals.get_node_or_null("BoostExhaust")
	if exhaust and exhaust is GPUParticles3D:
		exhaust.emitting = car.boost_power > 0

	# --- Drift sparks ---
	var sparks := visuals.get_node_or_null("DriftSparks")
	if sparks and sparks is GPUParticles3D:
		sparks.emitting = car.is_drifting and car.velocity.length() > 3.0
		# Change spark color based on drift charge
		if car.is_drifting and sparks.process_material is ParticleProcessMaterial:
			var charge_norm := car.drift_charge / car.stats.max_charge
			if charge_norm >= 1.0:
				sparks.process_material.color = Color(1.0, 0.3, 0.8)  # Pink/purple = full
			elif charge_norm >= 0.5:
				sparks.process_material.color = Color(0.3, 0.8, 1.0)  # Cyan = half
			else:
				sparks.process_material.color = Color(1.0, 0.7, 0.2)  # Orange = default

func _on_wave_completed(_wave: int) -> void:
	for drop in loot_spawner.active_drops.duplicate():
		loot_spawner.collect_drop(drop)
	enemy_spawner.clear_all()
	if GameManager.current_wave >= GameManager.max_waves:
		if victory_ui:
			victory_ui.show_victory()
		GameManager.change_state(GameManager.GameState.VICTORY)
	else:
		GameManager.change_state(GameManager.GameState.SHOP)
		if shop_ui:
			shop_ui.open_shop(
				GameManager.current_wave,
				shop_manager,
				economy,
				inventory,
				player_stats
			)

func _on_shop_closed() -> void:
	_apply_stats_to_car()
	weapon_mount_mgr.try_auto_merge()
	GameManager.close_shop()
	wave_manager.start_wave(GameManager.current_wave)

func _on_car_died() -> void:
	if game_over_ui:
		game_over_ui.show_game_over(GameManager.current_wave)
	GameManager.player_died()

func _on_level_up(level: int, choices: Array[Dictionary]) -> void:
	if level_up_ui and level_up_ui.has_method("show_choices"):
		level_up_ui.show_choices(level, choices, player_stats)

func _on_upgrade_selected(upgrade: Dictionary) -> void:
	level_up_mgr.apply_upgrade(upgrade, player_stats)
	_apply_stats_to_car()

func _apply_stats_to_car() -> void:
	car.stats.max_hp = player_stats.get_stat("max_hp", 100.0)
	car.stats.max_speed = player_stats.get_stat("max_speed", 28.0)
	car.stats.boost_speed = player_stats.get_stat("boost_speed", 45.0)
	car.stats.base_accel = player_stats.get_stat("base_accel", 35.0)
	car.stats.armor = player_stats.get_stat("armor", 0.0)
	car.stats.nitro_max = player_stats.get_stat("nitro_max", 100.0)
	car.stats.nitro_accumulation_rate = player_stats.get_stat("nitro_accumulation_rate", 10.0)
	car.stats.nitro_drain_rate = player_stats.get_stat("nitro_drain_rate", 25.0)
	car.stats.nitro_damage = player_stats.get_stat("nitro_damage", 30.0)
	car.nitro.configure(car.stats)
	var new_slots := player_stats.get_stat_int("weapon_slots", 4)
	while weapon_mount_mgr.get_slot_count() < new_slots:
		weapon_mount_mgr.add_slot()

func _create_boundaries() -> void:
	var walls := StaticBody3D.new()
	walls.name = "ArenaBoundary"
	walls.collision_layer = 32  # layer 5
	# North wall
	_add_wall(walls, Vector3(ARENA_SIZE / 2, 1, 0), Vector3(ARENA_SIZE, 3, 1))
	# South wall
	_add_wall(walls, Vector3(ARENA_SIZE / 2, 1, ARENA_SIZE), Vector3(ARENA_SIZE, 3, 1))
	# West wall
	_add_wall(walls, Vector3(0, 1, ARENA_SIZE / 2), Vector3(1, 3, ARENA_SIZE))
	# East wall
	_add_wall(walls, Vector3(ARENA_SIZE, 1, ARENA_SIZE / 2), Vector3(1, 3, ARENA_SIZE))
	add_child(walls)

func _add_wall(parent: StaticBody3D, pos: Vector3, size: Vector3) -> void:
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	collision.position = pos
	parent.add_child(collision)
	var wall_mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	wall_mesh.mesh = box
	wall_mesh.position = pos
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.4, 0.4, 0.5, 0.5)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	wall_mesh.material_override = mat
	parent.add_child(wall_mesh)
