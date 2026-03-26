extends Node
## Loads all JSON data files from data/ directory on startup.
## Provides typed accessors for game data.

var cars: Array = []
var weapons: Array = []
var enemies: Array = []
var items: Array = []
var waves: Array = []
var upgrades: Array = []
var wave_interpolation: Dictionary = {}
var shop_pricing: Dictionary = {}

func _ready() -> void:
	_load_all_data()
	EventBus.data_loaded.emit()

func _load_all_data() -> void:
	cars = _load_json_array("res://data/cars.json", "cars")
	weapons = _load_json_array("res://data/weapons.json", "weapons")
	enemies = _load_json_array("res://data/enemies.json", "enemies")
	items = _load_json_array("res://data/items.json", "items")
	upgrades = _load_json_array("res://data/upgrades.json", "upgrades")
	var waves_data := _load_json("res://data/waves.json")
	waves = waves_data.get("waves", [])
	wave_interpolation = waves_data.get("wave_interpolation", {})
	shop_pricing = waves_data.get("shop_pricing", {})

func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_warning("DataLoader: File not found: %s" % path)
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("DataLoader: Cannot open file: %s" % path)
		return {}
	var json_text := file.get_as_text()
	var json := JSON.new()
	var error := json.parse(json_text)
	if error != OK:
		push_warning("DataLoader: JSON parse error in %s: %s" % [path, json.get_error_message()])
		return {}
	return json.data if json.data is Dictionary else {}

func _load_json_array(path: String, key: String) -> Array:
	var data := _load_json(path)
	return data.get(key, [])

func get_car_data(car_id: String) -> Dictionary:
	for car in cars:
		if car.get("id") == car_id:
			return car
	return {}

func get_weapon_data(weapon_id: String) -> Dictionary:
	for weapon in weapons:
		if weapon.get("id") == weapon_id:
			return weapon
	return {}

func get_enemy_data(enemy_id: String) -> Dictionary:
	for enemy in enemies:
		if enemy.get("id") == enemy_id:
			return enemy
	return {}

func get_item_data(item_id: String) -> Dictionary:
	for item in items:
		if item.get("id") == item_id:
			return item
	return {}

func get_wave_data(wave_number: int) -> Dictionary:
	for wave in waves:
		if wave.get("wave_number") == wave_number:
			return wave
	return _interpolate_wave(wave_number)

func _interpolate_wave(wave_number: int) -> Dictionary:
	var duration := 20.0 + (wave_number - 1) * 3.68
	var spawn_rate := maxf(0.3, 1.5 - (wave_number - 1) * 0.058)
	var max_enemies := int(15 + (wave_number - 1) * 4.47)
	var elite_chance := maxf(0.0, (wave_number - 4) * 0.0125)
	return {
		"wave_number": wave_number,
		"duration_seconds": duration,
		"spawn_rate": spawn_rate,
		"max_enemies": mini(max_enemies, 100),
		"elite_chance": elite_chance,
		"has_boss": wave_number == 20,
		"shop_after": true,
	}
