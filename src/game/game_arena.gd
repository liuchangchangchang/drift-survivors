extends Node2D
## Main gameplay arena. Wires all systems together into a playable loop.

# Scene references
var car: CarController
var wave_manager: WaveManager
var enemy_spawner: EnemySpawner
var loot_spawner: LootSpawner
var weapon_mount_mgr: WeaponMountManager
var level_up_mgr: LevelUpManager

# Game state
var economy: EconomyManager
var inventory: Inventory
var player_stats: PlayerStats
var shop_manager: ShopManager

# UI references
var hud_node: Node
var shop_ui: Control
var level_up_ui: Control
var pause_menu: Control
var game_over_ui: Control
var victory_ui: Control

var selected_car_id: String = "car_starter"
var selected_weapon_id: String = "weapon_pistol"

const ARENA_SIZE := Vector2(3000, 3000)

func _ready() -> void:
	_create_background()
	_setup_systems()
	_setup_ui()
	_connect_signals()
	_start_first_wave()

func _create_background() -> void:
	# Dark ground
	var bg := ColorRect.new()
	bg.color = Color(0.12, 0.14, 0.18)
	bg.size = ARENA_SIZE
	bg.z_index = -10
	add_child(bg)
	# Grid lines for visual reference
	for i in range(0, int(ARENA_SIZE.x), 200):
		var vline := ColorRect.new()
		vline.color = Color(0.18, 0.20, 0.24)
		vline.size = Vector2(2, ARENA_SIZE.y)
		vline.position = Vector2(i, 0)
		vline.z_index = -9
		add_child(vline)
	for i in range(0, int(ARENA_SIZE.y), 200):
		var hline := ColorRect.new()
		hline.color = Color(0.18, 0.20, 0.24)
		hline.size = Vector2(ARENA_SIZE.x, 2)
		hline.position = Vector2(0, i)
		hline.z_index = -9
		add_child(hline)

func _setup_systems() -> void:
	# Economy
	economy = EconomyManager.new()
	economy.name = "EconomyManager"
	add_child(economy)

	# Inventory
	inventory = Inventory.new()

	# Player stats
	player_stats = PlayerStats.new()
	player_stats.name = "PlayerStats"
	add_child(player_stats)

	# Load car stats
	var car_data := DataLoader.get_car_data(selected_car_id)
	var base_stats: Dictionary = car_data.get("base_stats", {})
	player_stats.set_base_stats(base_stats)

	# Shop manager
	shop_manager = ShopManager.new()

	# Create car
	_create_car(base_stats)

	# Equip starting weapon
	var starting_weapon := WeaponFactory.create_weapon(selected_weapon_id, 1)
	if starting_weapon:
		weapon_mount_mgr.equip_weapon(starting_weapon)

	# Enemy spawner
	enemy_spawner = EnemySpawner.new()
	enemy_spawner.player = car
	enemy_spawner.name = "EnemySpawner"
	add_child(enemy_spawner)

	# Loot spawner
	loot_spawner = LootSpawner.new()
	loot_spawner.name = "LootSpawner"
	add_child(loot_spawner)

	# Wave manager
	wave_manager = WaveManager.new()
	wave_manager.spawner = enemy_spawner
	wave_manager.player = car
	wave_manager.name = "WaveManager"
	add_child(wave_manager)

	# Level up manager
	level_up_mgr = LevelUpManager.new()
	level_up_mgr.name = "LevelUpManager"
	add_child(level_up_mgr)

	# Projectile mover
	var proj_mover := ProjectileMover.new()
	proj_mover.name = "ProjectileMover"
	add_child(proj_mover)

	# Arena boundaries
	_create_boundaries()

func _create_car(base_stats: Dictionary) -> void:
	car = CarController.new()
	car.stats = CarStats.from_dict(base_stats)
	car.name = "Car"
	car.position = ARENA_SIZE / 2

	# Collision
	var car_collision := CollisionShape2D.new()
	var car_shape := RectangleShape2D.new()
	car_shape.size = Vector2(40, 60)
	car_collision.shape = car_shape
	car.add_child(car_collision)

	# Car body visual
	var body := ColorRect.new()
	body.color = Color(0.2, 0.6, 1.0)
	body.size = Vector2(40, 60)
	body.position = Vector2(-20, -30)
	car.add_child(body)

	# Front indicator (shows which way the car faces)
	var front := ColorRect.new()
	front.color = Color(0.9, 0.9, 0.2)
	front.size = Vector2(20, 10)
	front.position = Vector2(-10, -35)
	car.add_child(front)

	# Weapon mount manager
	weapon_mount_mgr = WeaponMountManager.new()
	weapon_mount_mgr.max_slots = int(base_stats.get("weapon_slots", 4))
	weapon_mount_mgr.name = "WeaponMountManager"
	car.add_child(weapon_mount_mgr)

	# Camera
	var camera := Camera2D.new()
	camera.zoom = Vector2(0.7, 0.7)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0
	car.add_child(camera)

	# Loot magnet
	var magnet := LootMagnet.new()
	magnet.name = "LootMagnet"
	magnet.collision_layer = 0
	magnet.collision_mask = 16
	car.add_child(magnet)

	add_child(car)

func _setup_ui() -> void:
	# HUD
	var hud_scene := load("res://scenes/game/hud.tscn")
	if hud_scene:
		hud_node = hud_scene.instantiate()
		add_child(hud_node)

	# Shop screen
	var shop_scene := load("res://scenes/ui/shop_screen.tscn")
	if shop_scene:
		shop_ui = shop_scene.instantiate()
		shop_ui.visible = false
		shop_ui.shop_closed.connect(_on_shop_closed)
		add_child(shop_ui)

	# Level up screen
	var lu_scene := load("res://scenes/ui/level_up_screen.tscn")
	if lu_scene:
		level_up_ui = lu_scene.instantiate()
		level_up_ui.visible = false
		level_up_ui.upgrade_selected.connect(_on_upgrade_selected)
		add_child(level_up_ui)

	# Pause menu
	var pause_scene := load("res://scenes/ui/pause_menu.tscn")
	if pause_scene:
		pause_menu = pause_scene.instantiate()
		add_child(pause_menu)

	# Game over
	var go_scene := load("res://scenes/ui/game_over.tscn")
	if go_scene:
		game_over_ui = go_scene.instantiate()
		add_child(game_over_ui)

	# Victory
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

func _on_wave_completed(_wave: int) -> void:
	for drop in loot_spawner.active_drops.duplicate():
		loot_spawner.collect_drop(drop)
	# Clear remaining enemies
	enemy_spawner.clear_all()
	# Open shop or victory
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
	car.stats.max_speed = player_stats.get_stat("max_speed", 500.0)
	car.stats.boost_speed = player_stats.get_stat("boost_speed", 750.0)
	car.stats.engine_power = player_stats.get_stat("engine_power", 400.0)
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
	var walls := StaticBody2D.new()
	walls.name = "ArenaBoundary"
	_add_wall(walls, Vector2(ARENA_SIZE.x / 2, 0), Vector2(ARENA_SIZE.x, 20))
	_add_wall(walls, Vector2(ARENA_SIZE.x / 2, ARENA_SIZE.y), Vector2(ARENA_SIZE.x, 20))
	_add_wall(walls, Vector2(0, ARENA_SIZE.y / 2), Vector2(20, ARENA_SIZE.y))
	_add_wall(walls, Vector2(ARENA_SIZE.x, ARENA_SIZE.y / 2), Vector2(20, ARENA_SIZE.y))
	add_child(walls)

func _add_wall(parent: StaticBody2D, pos: Vector2, size: Vector2) -> void:
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	collision.shape = shape
	collision.position = pos
	parent.add_child(collision)
	var rect := ColorRect.new()
	rect.color = Color(0.4, 0.4, 0.5)
	rect.size = size
	rect.position = pos - size / 2
	parent.add_child(rect)
