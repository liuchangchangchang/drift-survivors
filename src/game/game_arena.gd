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
	# Main directional light (warm sunset tone)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-55, -35, 0)
	light.light_energy = 0.9
	light.light_color = Color(1.0, 0.92, 0.85)
	light.shadow_enabled = true
	light.shadow_blur = 2.0
	add_child(light)
	# Cool fill light
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-30, 145, 0)
	fill.light_energy = 0.35
	fill.light_color = Color(0.6, 0.75, 1.0)
	fill.shadow_enabled = false
	add_child(fill)
	# Rim light (from below-behind for depth)
	var rim := DirectionalLight3D.new()
	rim.rotation_degrees = Vector3(20, 90, 0)
	rim.light_energy = 0.15
	rim.light_color = Color(0.8, 0.6, 1.0)
	rim.shadow_enabled = false
	add_child(rim)
	# World environment
	var env_node := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.01, 0.01, 0.04)
	environment.ambient_light_color = Color(0.2, 0.25, 0.35)
	environment.ambient_light_energy = 0.4
	environment.glow_enabled = true
	environment.glow_intensity = 0.6
	environment.glow_bloom = 0.15
	environment.glow_strength = 1.2
	environment.fog_enabled = true
	environment.fog_light_color = Color(0.05, 0.05, 0.12)
	environment.fog_density = 0.003
	env_node.environment = environment
	add_child(env_node)

func _create_ground() -> void:
	var center := ARENA_SIZE / 2.0

	# Main ground - dark asphalt
	var ground := MeshInstance3D.new()
	var plane_mesh := PlaneMesh.new()
	plane_mesh.size = Vector2(ARENA_SIZE, ARENA_SIZE)
	ground.mesh = plane_mesh
	ground.position = Vector3(center, 0, center)
	var ground_mat := StandardMaterial3D.new()
	ground_mat.albedo_color = Color(0.11, 0.12, 0.15)
	ground_mat.roughness = 0.95
	ground.material_override = ground_mat
	add_child(ground)

	# Outer void plane (extends beyond arena, darker)
	var void_plane := MeshInstance3D.new()
	var void_mesh := PlaneMesh.new()
	void_mesh.size = Vector2(ARENA_SIZE * 3, ARENA_SIZE * 3)
	void_plane.mesh = void_mesh
	void_plane.position = Vector3(center, -0.05, center)
	var void_mat := StandardMaterial3D.new()
	void_mat.albedo_color = Color(0.03, 0.03, 0.06)
	void_mat.roughness = 1.0
	void_plane.material_override = void_mat
	add_child(void_plane)

	var rng := RandomNumberGenerator.new()
	rng.seed = 42

	# --- Asphalt texture patches (color variation) ---
	var patch_colors := [
		Color(0.08, 0.09, 0.11),
		Color(0.10, 0.11, 0.14),
		Color(0.13, 0.14, 0.17),
		Color(0.09, 0.10, 0.15),
	]
	var patch_mats: Array[StandardMaterial3D] = []
	for c in patch_colors:
		var pm := StandardMaterial3D.new()
		pm.albedo_color = c
		pm.roughness = 0.95
		patch_mats.append(pm)
	for _i in 120:
		var patch := MeshInstance3D.new()
		var pmesh := QuadMesh.new()
		pmesh.size = Vector2(rng.randf_range(3.0, 12.0), rng.randf_range(3.0, 12.0))
		pmesh.orientation = PlaneMesh.FACE_Y
		patch.mesh = pmesh
		patch.position = Vector3(
			rng.randf_range(2, ARENA_SIZE - 2),
			0.002 + rng.randf_range(0, 0.003),
			rng.randf_range(2, ARENA_SIZE - 2))
		patch.rotation.y = rng.randf_range(0, TAU)
		patch.material_override = patch_mats[rng.randi() % patch_mats.size()]
		add_child(patch)

	# --- Road lane dashes (white, every 30 units) ---
	var lane_mat := StandardMaterial3D.new()
	lane_mat.albedo_color = Color(0.4, 0.4, 0.35)
	lane_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for lane_i in range(30, int(ARENA_SIZE), 30):
		for d in range(3, int(ARENA_SIZE) - 3, 7):
			# Horizontal dashes
			var dh := MeshInstance3D.new()
			var dhm := BoxMesh.new()
			dhm.size = Vector3(3.5, 0.008, 0.1)
			dh.mesh = dhm
			dh.position = Vector3(d + 1.75, 0.006, lane_i)
			dh.material_override = lane_mat
			add_child(dh)
			# Vertical dashes
			var dv := MeshInstance3D.new()
			var dvm := BoxMesh.new()
			dvm.size = Vector3(0.1, 0.008, 3.5)
			dv.mesh = dvm
			dv.position = Vector3(lane_i, 0.006, d + 1.75)
			dv.material_override = lane_mat
			add_child(dv)

	# --- Edge line (solid white border inside walls) ---
	var edge_mat := StandardMaterial3D.new()
	edge_mat.albedo_color = Color(0.6, 0.6, 0.5)
	edge_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var edge_w := 0.2
	var edge_inset := 1.5
	# North
	_add_ground_stripe(Vector3(center, 0.007, edge_inset), Vector3(ARENA_SIZE - 4, 0.008, edge_w), edge_mat)
	# South
	_add_ground_stripe(Vector3(center, 0.007, ARENA_SIZE - edge_inset), Vector3(ARENA_SIZE - 4, 0.008, edge_w), edge_mat)
	# West
	_add_ground_stripe(Vector3(edge_inset, 0.007, center), Vector3(edge_w, 0.008, ARENA_SIZE - 4), edge_mat)
	# East
	_add_ground_stripe(Vector3(ARENA_SIZE - edge_inset, 0.007, center), Vector3(edge_w, 0.008, ARENA_SIZE - 4), edge_mat)

	# --- Decorative corner markers (glowing pylons) ---
	var pylon_mat := StandardMaterial3D.new()
	pylon_mat.albedo_color = Color(0.2, 0.5, 1.0)
	pylon_mat.emission_enabled = true
	pylon_mat.emission = Color(0.2, 0.5, 1.0)
	pylon_mat.emission_energy_multiplier = 2.0
	var corners := [
		Vector3(4, 0, 4), Vector3(ARENA_SIZE - 4, 0, 4),
		Vector3(4, 0, ARENA_SIZE - 4), Vector3(ARENA_SIZE - 4, 0, ARENA_SIZE - 4),
	]
	for cpos in corners:
		var pylon := MeshInstance3D.new()
		var pcyl := CylinderMesh.new()
		pcyl.top_radius = 0.3
		pcyl.bottom_radius = 0.4
		pcyl.height = 2.5
		pylon.mesh = pcyl
		pylon.position = cpos + Vector3(0, 1.25, 0)
		pylon.material_override = pylon_mat
		add_child(pylon)
		# Point light on pylon
		var plight := OmniLight3D.new()
		plight.light_color = Color(0.3, 0.6, 1.0)
		plight.light_energy = 1.5
		plight.omni_range = 8.0
		plight.position = cpos + Vector3(0, 2.8, 0)
		add_child(plight)

	# --- Scattered ground lights along edges ---
	var glight_mat := StandardMaterial3D.new()
	glight_mat.albedo_color = Color(1.0, 0.7, 0.3)
	glight_mat.emission_enabled = true
	glight_mat.emission = Color(1.0, 0.6, 0.2)
	glight_mat.emission_energy_multiplier = 2.5
	for li in range(15, int(ARENA_SIZE), 30):
		for edge_pos in [Vector3(li, 0.15, 2.5), Vector3(li, 0.15, ARENA_SIZE - 2.5),
						 Vector3(2.5, 0.15, li), Vector3(ARENA_SIZE - 2.5, 0.15, li)]:
			var gl := MeshInstance3D.new()
			var gl_mesh := SphereMesh.new()
			gl_mesh.radius = 0.15
			gl_mesh.height = 0.3
			gl.mesh = gl_mesh
			gl.position = edge_pos
			gl.material_override = glight_mat
			add_child(gl)

func _add_ground_stripe(pos: Vector3, size: Vector3, mat: StandardMaterial3D) -> void:
	var stripe := MeshInstance3D.new()
	var smesh := BoxMesh.new()
	smesh.size = size
	stripe.mesh = smesh
	stripe.position = pos
	stripe.material_override = mat
	add_child(stripe)

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
	enemy_spawner.arena_size = ARENA_SIZE
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

	# Visuals from content scene
	var visuals := Node3D.new()
	visuals.name = "Visuals"
	var car_scene: PackedScene = DataLoader.get_car_scene(selected_car_id)
	if car_scene:
		var car_model: Node3D = car_scene.instantiate()
		# Reparent all visual children into Visuals node
		for child in car_model.get_children():
			car_model.remove_child(child)
			visuals.add_child(child)
		car_model.free()

	# Weapon mount manager (inside BodyWrap so weapons rotate with car)
	weapon_mount_mgr = WeaponMountManager.new()
	weapon_mount_mgr.max_slots = int(base_stats.get("weapon_slots", 4))
	weapon_mount_mgr.name = "WeaponMountManager"
	var body_wrap: Node3D = visuals.get_node_or_null("BodyWrap")
	if body_wrap:
		body_wrap.add_child(weapon_mount_mgr)
	else:
		visuals.add_child(weapon_mount_mgr)

	car.add_child(visuals)

	# Skidmark system
	var skidmarks := SkidmarkSystem.new()
	skidmarks.name = "SkidmarkSystem"
	car.add_child(skidmarks)

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

var _item_display_count: int = 0
var _pending_levelups: Array[Dictionary] = []  # [{level, choices}]
var _levelup_arrow: Node3D = null
var _levelup_label: Label3D = null

func _connect_signals() -> void:
	EventBus.car_died.connect(_on_car_died)
	EventBus.enemy_killed.connect(enemy_spawner.on_enemy_killed)
	EventBus.material_collected.connect(func(amount: int): economy.add_materials(amount))
	EventBus.item_purchased.connect(_on_item_visual)
	EventBus.upgrade_chosen.connect(_on_upgrade_visual)
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

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("level_up_open") and not _pending_levelups.is_empty():
		if GameManager.current_state == GameManager.GameState.PLAYING:
			_open_pending_levelup()
			get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	# Animate level-up arrow (bob up and down)
	if _levelup_arrow and car and car.is_alive:
		_levelup_arrow.position.y = 4.5 + sin(Time.get_ticks_msec() * 0.004) * 0.3
	if not car or not car.is_alive:
		return
	var visuals := car.get_node_or_null("Visuals")
	if not visuals:
		return

	# --- Yaw: rotate visuals to match visual_angle ---
	# visual_angle uses atan2(z,x). Car model faces -Z.
	# To make local -Z point toward (cos(va), 0, sin(va)): yaw = -va - PI/2
	var target_yaw := -car.visual_angle - PI / 2
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

	# --- Boost exhaust particles (both pipes) ---
	var is_boosting := car.boost_power > 0
	for ex_name in ["BoostExhaustL", "BoostExhaustR"]:
		var ex := visuals.get_node_or_null(ex_name)
		if ex and ex is GPUParticles3D:
			ex.emitting = is_boosting

	# --- Drift sparks (both rear wheels) ---
	var is_spark := car.is_drifting and car.velocity.length() > 3.0
	var charge_norm := car.drift_charge / car.stats.max_charge if car.stats.max_charge > 0 else 0.0
	var spark_color: Color
	if charge_norm >= 1.0:
		spark_color = Color(1.0, 0.2, 0.8)
	elif charge_norm >= 0.5:
		spark_color = Color(0.3, 0.8, 1.0)
	else:
		spark_color = Color(1.0, 0.7, 0.2)
	for sp_name in ["DriftSparksL", "DriftSparksR"]:
		var sp := visuals.get_node_or_null(sp_name)
		if sp and sp is GPUParticles3D:
			sp.emitting = is_spark
			if is_spark and sp.process_material is ParticleProcessMaterial:
				sp.process_material.color = spark_color

func _on_wave_completed(_wave: int) -> void:
	for drop in loot_spawner.active_drops.duplicate():
		loot_spawner.collect_drop(drop)
	# Play poof effect on all enemies before clearing
	for enemy in enemy_spawner.active_enemies:
		if is_instance_valid(enemy):
			_spawn_poof_effect(enemy.global_position, _get_enemy_color(enemy))
	enemy_spawner.clear_all()
	# Poof effect on player car
	if car and car.is_alive:
		_spawn_poof_effect(car.global_position, Color(0.3, 0.6, 1.0))
		car.visible = false
		car.set_physics_process(false)
	# Delay, then transition
	await get_tree().create_timer(1.0).timeout
	if GameManager.current_wave >= GameManager.max_waves:
		car.visible = true
		car.set_physics_process(true)
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
	# Respawn car at center
	car.global_position = Vector3(ARENA_SIZE / 2, 0, ARENA_SIZE / 2)
	car.velocity = Vector3.ZERO
	car.visible = true
	car.set_physics_process(true)
	_spawn_poof_effect(car.global_position, Color(0.3, 0.8, 1.0))
	# Re-validate environment (workaround for gl_compatibility SubViewport leaks)
	_reapply_environment()
	GameManager.close_shop()
	wave_manager.start_wave(GameManager.current_wave)

func _reapply_environment() -> void:
	# Find and re-set the WorldEnvironment to ensure it's active
	for child in get_children():
		if child is WorldEnvironment:
			var we: WorldEnvironment = child
			var env_res: Environment = we.environment
			we.environment = null
			we.environment = env_res
			return

func _on_car_died() -> void:
	if game_over_ui:
		game_over_ui.show_game_over(GameManager.current_wave)
	GameManager.player_died()

func _on_level_up(level: int, choices: Array[Dictionary]) -> void:
	_pending_levelups.append({"level": level, "choices": choices})
	_show_levelup_arrow()

func _show_levelup_arrow() -> void:
	if _levelup_arrow:
		return  # Already showing
	_levelup_arrow = Node3D.new()
	_levelup_arrow.name = "LevelUpArrow"
	# Green arrow mesh (cone pointing down)
	var arrow := MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = 0.8
	cone.height = 1.2
	arrow.mesh = cone
	arrow.rotation_degrees = Vector3(180, 0, 0)
	arrow.position = Vector3(0, 0, 0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 1.0, 0.3)
	mat.emission_enabled = true
	mat.emission = Color(0.2, 1.0, 0.3)
	mat.emission_energy_multiplier = 4.0
	arrow.material_override = mat
	_levelup_arrow.add_child(arrow)
	# Key prompt label
	_levelup_label = Label3D.new()
	_levelup_label.text = "[ TAB ]"
	_levelup_label.font_size = 96
	_levelup_label.modulate = Color(0.3, 1.0, 0.4)
	_levelup_label.outline_modulate = Color(0, 0, 0)
	_levelup_label.outline_size = 16
	_levelup_label.position = Vector3(0, 1.2, 0)
	_levelup_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_levelup_arrow.add_child(_levelup_label)
	car.add_child(_levelup_arrow)

func _hide_levelup_arrow() -> void:
	if _levelup_arrow:
		_levelup_arrow.queue_free()
		_levelup_arrow = null
		_levelup_label = null

func _open_pending_levelup() -> void:
	if _pending_levelups.is_empty():
		return
	var data: Dictionary = _pending_levelups.pop_front()
	if _pending_levelups.is_empty():
		_hide_levelup_arrow()
	if level_up_ui and level_up_ui.has_method("show_choices"):
		level_up_ui.show_choices(data["level"], data["choices"], player_stats)

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

func _on_item_visual(item_id: String) -> void:
	var item_data := DataLoader.get_item_data(item_id)
	if item_data.is_empty():
		return
	_add_item_to_car(item_data)

func _on_upgrade_visual(upgrade_id: String) -> void:
	# Find upgrade data
	for u in DataLoader.upgrades:
		if u.get("id", "") == upgrade_id:
			_add_item_to_car(u)
			return

func _add_item_to_car(item_data: Dictionary) -> void:
	var visuals := car.get_node_or_null("Visuals")
	if not visuals:
		return
	var body_wrap := visuals.get_node_or_null("BodyWrap")
	if not body_wrap:
		return
	var idx := _item_display_count
	_item_display_count += 1
	# Car surface positions: roof (y=0.6), hood (y=0.35, z<0), trunk (y=0.35, z>0)
	# Chassis is 1.8 x 0.5 x 2.8 centered at y=0.35
	# Roof top = 0.6, hood/trunk top = 0.35, sides at x=±0.9
	var surface_positions := [
		# Roof (flat on top of chassis)
		Vector3(-0.5, 0.61, -0.5), Vector3(0.0, 0.61, -0.5),
		Vector3(0.5, 0.61, -0.5), Vector3(-0.5, 0.61, 0.0),
		Vector3(0.0, 0.61, 0.0), Vector3(0.5, 0.61, 0.0),
		Vector3(-0.5, 0.61, 0.5), Vector3(0.0, 0.61, 0.5),
		Vector3(0.5, 0.61, 0.5),
		# Hood front
		Vector3(-0.3, 0.61, -1.0), Vector3(0.3, 0.61, -1.0),
		# Trunk rear
		Vector3(-0.3, 0.61, 1.0), Vector3(0.3, 0.61, 1.0),
	]
	var pos: Vector3
	if idx < surface_positions.size():
		pos = surface_positions[idx]
	else:
		# Overflow: stack on roof
		var oi := idx - surface_positions.size()
		pos = Vector3(
			fmod(oi * 0.22, 0.8) - 0.4,
			0.61 + 0.16 * (oi / 4),
			fmod(oi * 0.25, 0.6) - 0.3)
	var icon := Node3D.new()
	icon.name = "ItemIcon_%d" % idx
	var color := _item_icon_color(item_data)
	var mesh_inst := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.12, 0.06, 0.12)  # Flat, sits on surface
	mesh_inst.mesh = box
	mesh_inst.rotation_degrees = Vector3(0, 45, 0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 2.0
	mat.metallic = 0.7
	mat.roughness = 0.15
	mesh_inst.material_override = mat
	icon.add_child(mesh_inst)
	icon.position = pos
	body_wrap.add_child(icon)

func _item_icon_color(item_data: Dictionary) -> Color:
	var cat: String = item_data.get("category", "")
	match cat:
		"defense": return Color(0.3, 0.5, 0.9)
		"offense": return Color(0.9, 0.3, 0.2)
		"speed": return Color(0.2, 0.9, 0.3)
		"utility": return Color(0.9, 0.8, 0.2)
		"special": return Color(0.8, 0.3, 0.9)
	var rarity: String = item_data.get("rarity", "common")
	match rarity:
		"uncommon": return Color(0.2, 0.8, 0.3)
		"rare": return Color(0.3, 0.5, 1.0)
		"legendary": return Color(1.0, 0.7, 0.1)
	return Color(0.6, 0.6, 0.7)

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
	# Glowing barrier wall
	var wall_mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	wall_mesh.mesh = box
	wall_mesh.position = pos
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.15, 0.25, 0.5, 0.3)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(0.1, 0.3, 0.7)
	mat.emission_energy_multiplier = 0.8
	wall_mesh.material_override = mat
	parent.add_child(wall_mesh)

func _spawn_poof_effect(pos: Vector3, color: Color) -> void:
	var particles := GPUParticles3D.new()
	particles.emitting = true
	particles.one_shot = true
	particles.amount = 24
	particles.lifetime = 0.8
	particles.explosiveness = 0.9
	particles.visibility_aabb = AABB(Vector3(-5, -3, -5), Vector3(10, 6, 10))
	var pmat := ParticleProcessMaterial.new()
	pmat.direction = Vector3(0, 1, 0)
	pmat.spread = 180.0
	pmat.initial_velocity_min = 3.0
	pmat.initial_velocity_max = 7.0
	pmat.gravity = Vector3(0, -2, 0)
	pmat.scale_min = 0.5
	pmat.scale_max = 1.5
	pmat.damping_min = 3.0
	pmat.damping_max = 5.0
	pmat.color = color
	particles.process_material = pmat
	var draw_mat := StandardMaterial3D.new()
	draw_mat.albedo_color = Color(color.r, color.g, color.b, 0.7)
	draw_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	draw_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	draw_mat.emission_enabled = true
	draw_mat.emission = color
	draw_mat.emission_energy_multiplier = 2.0
	var draw_mesh := QuadMesh.new()
	draw_mesh.size = Vector2(0.8, 0.8)
	draw_mesh.material = draw_mat
	particles.draw_pass_1 = draw_mesh
	particles.position = pos + Vector3(0, 0.5, 0)
	add_child(particles)
	# Auto-cleanup
	var timer := get_tree().create_timer(2.0)
	timer.timeout.connect(func(): if is_instance_valid(particles): particles.queue_free())

func _get_enemy_color(enemy: EnemyBase) -> Color:
	var vis := enemy.get_node_or_null("EnemyVisual")
	if vis:
		for child in vis.get_children():
			if child is MeshInstance3D and child.material_override:
				return child.material_override.albedo_color
	return Color(0.9, 0.2, 0.2)
