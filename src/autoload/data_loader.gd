extends Node
## Loads game data from .tscn content scenes (auto-discovery) and JSON data files.
## Provides typed accessors for game data.

var cars: Array = []
var weapons: Array = []
var enemies: Array = []
var items: Array = []
var waves: Array = []
var upgrades: Array = []
var wave_interpolation: Dictionary = {}
var shop_pricing: Dictionary = {}

var _car_scenes: Dictionary = {}
var _weapon_scenes: Dictionary = {}
var _item_scenes: Dictionary = {}
var _upgrade_scenes: Dictionary = {}

func _ready() -> void:
	_load_all_data()
	EventBus.data_loaded.emit()

func _load_all_data() -> void:
	# Content scenes (auto-discovered from directories)
	cars = _scan_content_scenes("res://scenes/content/cars/", _car_scenes)
	weapons = _scan_content_scenes("res://scenes/content/weapons/", _weapon_scenes)
	items = _scan_content_scenes("res://scenes/content/items/", _item_scenes)
	upgrades = _scan_content_scenes("res://scenes/content/upgrades/", _upgrade_scenes)
	# JSON data (enemies and waves remain JSON-based)
	enemies = _load_json_array("res://data/enemies.json", "enemies")
	var waves_data := _load_json("res://data/waves.json")
	waves = waves_data.get("waves", [])
	wave_interpolation = waves_data.get("wave_interpolation", {})
	shop_pricing = waves_data.get("shop_pricing", {})

func _scan_content_scenes(dir_path: String, scene_dict: Dictionary) -> Array:
	var result: Array = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		push_warning("DataLoader: Cannot open directory: %s" % dir_path)
		return result
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tscn"):
			var full_path := dir_path + file_name
			var packed: PackedScene = load(full_path)
			if packed:
				var instance: Node3D = packed.instantiate()
				if instance.has_method("to_data_dict"):
					var data: Dictionary = instance.to_data_dict()
					var content_id: String = data.get("id", "")
					if content_id != "":
						result.append(data)
						scene_dict[content_id] = packed
				instance.free()
		file_name = dir.get_next()
	dir.list_dir_end()
	return result

func get_car_scene(car_id: String) -> PackedScene:
	return _car_scenes.get(car_id)

func get_weapon_scene(weapon_id: String) -> PackedScene:
	return _weapon_scenes.get(weapon_id)

func get_item_scene(item_id: String) -> PackedScene:
	return _item_scenes.get(item_id)

func get_upgrade_scene(upgrade_id: String) -> PackedScene:
	return _upgrade_scenes.get(upgrade_id)

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
