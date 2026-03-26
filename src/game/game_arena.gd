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
var hud: Node  # CanvasLayer
var shop_ui: Control
var level_up_ui: Control
var pause_menu: Control
var game_over_ui: Control
var victory_ui: Control

var selected_car_id: String = "car_starter"
var selected_weapon_id: String = "weapon_pistol"

const ARENA_SIZE := Vector2(3000, 3000)

func _ready() -> void:
	_setup_systems()
	_connect_signals()
	_start_first_wave()

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
	car = CarController.new()
	car.stats = CarStats.from_dict(base_stats)
	car.name = "Car"
	car.position = Vector2(ARENA_SIZE.x / 2, ARENA_SIZE.y / 2)
	# Add collision shape
	var car_collision := CollisionShape2D.new()
	var car_shape := RectangleShape2D.new()
	car_shape.size = Vector2(40, 60)
	car_collision.shape = car_shape
	car.add_child(car_collision)
	# Add visual placeholder
	var car_sprite := ColorRect.new()
	car_sprite.color = Color(0.2, 0.6, 1.0)
	car_sprite.size = Vector2(40, 60)
	car_sprite.position = Vector2(-20, -30)
	car.add_child(car_sprite)
	# Weapon mount manager
	weapon_mount_mgr = WeaponMountManager.new()
	weapon_mount_mgr.max_slots = int(base_stats.get("weapon_slots", 4))
	weapon_mount_mgr.name = "WeaponMountManager"
	car.add_child(weapon_mount_mgr)
	# Camera
	var camera := Camera2D.new()
	camera.zoom = Vector2(0.8, 0.8)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0
	car.add_child(camera)
	# Loot magnet
	var magnet := LootMagnet.new()
	magnet.name = "LootMagnet"
	magnet.collision_layer = 0
	magnet.collision_mask = 16  # Layer 4 = loot (bit 4)
	car.add_child(magnet)
	add_child(car)

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

	# Arena boundaries
	_create_boundaries()

func _connect_signals() -> void:
	EventBus.car_died.connect(_on_car_died)
	EventBus.wave_ended.connect(_on_wave_ended)
	EventBus.enemy_killed.connect(enemy_spawner.on_enemy_killed)
	EventBus.material_collected.connect(func(amount): economy.add_materials(amount))
	wave_manager.wave_completed.connect(_on_wave_completed)
	level_up_mgr.level_up_ready.connect(_on_level_up)

func _start_first_wave() -> void:
	wave_manager.start_wave(GameManager.current_wave)

func _physics_process(_delta: float) -> void:
	if car and car.is_alive:
		# HP regen
		var regen := player_stats.get_stat("hp_regen", 1.0)
		if regen > 0:
			car.heal(regen * _delta)

func _on_wave_completed(wave: int) -> void:
	# Collect all remaining loot
	for drop in loot_spawner.active_drops.duplicate():
		loot_spawner.collect_drop(drop)

func _on_wave_ended(wave: int) -> void:
	if wave >= GameManager.max_waves:
		# Victory
		GameManager.change_state(GameManager.GameState.VICTORY)
	else:
		# Open shop
		GameManager.change_state(GameManager.GameState.SHOP)

func _on_car_died() -> void:
	GameManager.player_died()

func _on_level_up(level: int, choices: Array[Dictionary]) -> void:
	# Will be handled by level_up_ui when integrated
	pass

func open_shop() -> void:
	if shop_ui:
		shop_ui.open_shop(
			GameManager.current_wave,
			shop_manager,
			economy,
			inventory,
			player_stats
		)

func close_shop() -> void:
	# Apply stat changes to car
	_apply_stats_to_car()
	# Try auto-merge weapons
	weapon_mount_mgr.try_auto_merge()
	# Start next wave
	GameManager.close_shop()
	wave_manager.start_wave(GameManager.current_wave)

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
	# Update weapon slots
	var new_slots := player_stats.get_stat_int("weapon_slots", 4)
	while weapon_mount_mgr.get_slot_count() < new_slots:
		weapon_mount_mgr.add_slot()

func _create_boundaries() -> void:
	var walls := StaticBody2D.new()
	walls.name = "ArenaBoundary"
	# Top
	_add_wall(walls, Vector2(ARENA_SIZE.x / 2, 0), Vector2(ARENA_SIZE.x, 20))
	# Bottom
	_add_wall(walls, Vector2(ARENA_SIZE.x / 2, ARENA_SIZE.y), Vector2(ARENA_SIZE.x, 20))
	# Left
	_add_wall(walls, Vector2(0, ARENA_SIZE.y / 2), Vector2(20, ARENA_SIZE.y))
	# Right
	_add_wall(walls, Vector2(ARENA_SIZE.x, ARENA_SIZE.y / 2), Vector2(20, ARENA_SIZE.y))
	add_child(walls)

func _add_wall(parent: StaticBody2D, pos: Vector2, size: Vector2) -> void:
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	collision.shape = shape
	collision.position = pos
	parent.add_child(collision)
	# Visual
	var rect := ColorRect.new()
	rect.color = Color(0.3, 0.3, 0.3)
	rect.size = size
	rect.position = pos - size / 2
	parent.add_child(rect)
