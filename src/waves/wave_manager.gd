class_name WaveManager
extends Node
## Controls wave progression, timers, and enemy spawning schedule.

signal wave_completed(wave_number: int)
signal wave_timer_updated(time_remaining: float)

var current_wave: int = 0
var time_remaining: float = 0.0
var is_active: bool = false
var spawn_timer: float = 0.0
var spawner: EnemySpawner = null
var player: Node3D = null

func start_wave(wave_number: int) -> void:
	current_wave = wave_number
	var wave_data := DataLoader.get_wave_data(wave_number)
	time_remaining = wave_data.get("duration_seconds", 30.0)
	spawn_timer = 0.0
	is_active = true
	if spawner:
		spawner.max_enemies = int(wave_data.get("max_enemies", 50))

func _physics_process(delta: float) -> void:
	if not is_active:
		return
	# Update wave timer
	time_remaining -= delta
	wave_timer_updated.emit(time_remaining)
	EventBus.wave_timer_tick.emit(time_remaining)

	if time_remaining <= 0.0:
		_complete_wave()
		return

	# Spawn enemies
	spawn_timer -= delta
	if spawn_timer <= 0.0:
		_spawn_wave_enemies()

func _spawn_wave_enemies() -> void:
	var wave_data := DataLoader.get_wave_data(current_wave)
	var spawn_rate: float = wave_data.get("spawn_rate", 1.0)
	spawn_timer = spawn_rate

	if spawner == null:
		return

	var enemy_types: Array = wave_data.get("enemy_types", ["enemy_basic"])
	var elite_chance: float = wave_data.get("elite_chance", 0.0)

	# Decide what to spawn
	var enemy_id: String
	if randf() < elite_chance:
		enemy_id = _pick_elite_enemy()
	else:
		enemy_id = enemy_types[randi() % enemy_types.size()]

	# Get enemy data with scaling
	var enemy_json := DataLoader.get_enemy_data(enemy_id)
	if enemy_json.is_empty():
		return
	var enemy_data := EnemyData.from_json_scaled(enemy_json, current_wave)
	spawner.spawn_enemy(enemy_data)

func _pick_elite_enemy() -> String:
	var elites: Array[String] = []
	for enemy in DataLoader.enemies:
		if enemy.get("type") == "elite" and int(enemy.get("min_wave", 99)) <= current_wave:
			elites.append(enemy.get("id", ""))
	if elites.is_empty():
		return "enemy_basic"
	return elites[randi() % elites.size()]

func _complete_wave() -> void:
	is_active = false
	time_remaining = 0.0
	# Spawn boss if needed
	var wave_data := DataLoader.get_wave_data(current_wave)
	if wave_data.get("has_boss", false):
		_spawn_boss(wave_data)
	wave_completed.emit(current_wave)
	EventBus.wave_ended.emit(current_wave)

func _spawn_boss(wave_data: Dictionary) -> void:
	var boss_id: String = wave_data.get("boss_id", "enemy_boss_overlord")
	var boss_json := DataLoader.get_enemy_data(boss_id)
	if boss_json.is_empty():
		return
	var boss_data := EnemyData.from_json_scaled(boss_json, current_wave)
	if spawner:
		spawner.spawn_enemy(boss_data)

func stop() -> void:
	is_active = false
	time_remaining = 0.0

func get_wave_duration(wave_number: int) -> float:
	var wave_data := DataLoader.get_wave_data(wave_number)
	return wave_data.get("duration_seconds", 30.0)

func get_progress() -> float:
	if not is_active:
		return 0.0
	var total := get_wave_duration(current_wave)
	if total <= 0:
		return 1.0
	return 1.0 - (time_remaining / total)
