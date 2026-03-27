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
	# Directional light (sun)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-50, -30, 0)
	light.light_energy = 1.2
	light.shadow_enabled = true
	add_child(light)
	# World environment
	var env_node := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.05, 0.05, 0.1)
	environment.ambient_light_color = Color(0.3, 0.35, 0.45)
	environment.ambient_light_energy = 0.6
	env_node.environment = environment
	add_child(env_node)

func _create_ground() -> void:
	# Ground plane
	var ground := MeshInstance3D.new()
	var plane_mesh := PlaneMesh.new()
	plane_mesh.size = Vector2(ARENA_SIZE, ARENA_SIZE)
	ground.mesh = plane_mesh
	ground.position = Vector3(ARENA_SIZE / 2, 0, ARENA_SIZE / 2)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.15, 0.17, 0.22)
	ground.material_override = mat
	add_child(ground)
	# Grid lines (simple approach: thin box meshes)
	var grid_mat := StandardMaterial3D.new()
	grid_mat.albedo_color = Color(0.22, 0.24, 0.30)
	for i in range(0, int(ARENA_SIZE) + 1, 10):
		# Vertical line (along Z)
		var vline := MeshInstance3D.new()
		var vbox := BoxMesh.new()
		vbox.size = Vector3(0.05, 0.02, ARENA_SIZE)
		vline.mesh = vbox
		vline.position = Vector3(i, 0.01, ARENA_SIZE / 2)
		vline.material_override = grid_mat
		add_child(vline)
		# Horizontal line (along X)
		var hline := MeshInstance3D.new()
		var hbox := BoxMesh.new()
		hbox.size = Vector3(ARENA_SIZE, 0.02, 0.05)
		hline.mesh = hbox
		hline.position = Vector3(ARENA_SIZE / 2, 0.01, i)
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
	car.collision_layer = 1  # car
	car.collision_mask = 2 | 16 | 32  # enemies + arena_boundary

	# Collision shape
	var car_collision := CollisionShape3D.new()
	var car_shape := BoxShape3D.new()
	car_shape.size = Vector3(2.0, 1.0, 3.0)
	car_collision.shape = car_shape
	car_collision.position = Vector3(0, 0.5, 0)
	car.add_child(car_collision)

	# Visuals node (rotates independently based on visual_angle)
	var visuals := Node3D.new()
	visuals.name = "Visuals"
	# Car body mesh
	var body_mesh := MeshInstance3D.new()
	var body_box := BoxMesh.new()
	body_box.size = Vector3(2.0, 0.8, 3.0)
	body_mesh.mesh = body_box
	body_mesh.position = Vector3(0, 0.5, 0)
	var body_mat := StandardMaterial3D.new()
	body_mat.albedo_color = Color(0.2, 0.6, 1.0)
	body_mesh.material_override = body_mat
	visuals.add_child(body_mesh)
	# Front indicator
	var front_mesh := MeshInstance3D.new()
	var front_box := BoxMesh.new()
	front_box.size = Vector3(1.0, 0.3, 0.5)
	front_mesh.mesh = front_box
	front_mesh.position = Vector3(0, 0.9, -1.5)
	var front_mat := StandardMaterial3D.new()
	front_mat.albedo_color = Color(0.9, 0.9, 0.2)
	front_mat.emission_enabled = true
	front_mat.emission = Color(0.9, 0.9, 0.2)
	front_mesh.material_override = front_mat
	visuals.add_child(front_mesh)
	car.add_child(visuals)

	# Weapon mount manager
	weapon_mount_mgr = WeaponMountManager.new()
	weapon_mount_mgr.max_slots = int(base_stats.get("weapon_slots", 4))
	weapon_mount_mgr.name = "WeaponMountManager"
	car.add_child(weapon_mount_mgr)

	# Loot magnet
	var magnet := LootMagnet.new()
	magnet.name = "LootMagnet"
	magnet.collision_layer = 0
	magnet.collision_mask = 16  # loot layer
	car.add_child(magnet)

	add_child(car)

	# Camera (independent, not child of car)
	camera = CameraController.new()
	camera.name = "GameCamera"
	camera.target = car
	camera.position = car.position + camera.offset
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

func _process(_delta: float) -> void:
	# Rotate car visuals to match visual_angle
	if car and car.is_alive:
		var visuals := car.get_node_or_null("Visuals")
		if visuals:
			# visual_angle is atan2(z, x) convention
			# Godot Y rotation: 0 = facing -Z, increases CCW
			visuals.rotation.y = -car.visual_angle + PI / 2

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
	car.stats.max_speed = player_stats.get_stat("max_speed", 25.0)
	car.stats.boost_speed = player_stats.get_stat("boost_speed", 37.5)
	car.stats.base_accel = player_stats.get_stat("base_accel", 12.0)
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
