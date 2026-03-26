extends Node
## Save/Load game data. Uses Steam Cloud when available, local file fallback.

const SAVE_PATH := "user://save_data.json"

var save_data: Dictionary = {
	"best_wave": 0,
	"total_runs": 0,
	"total_kills": 0,
	"cars_unlocked": ["car_starter"],
	"settings": {
		"sfx_volume": 1.0,
		"music_volume": 0.7,
	}
}

func _ready() -> void:
	load_game()

func save_game() -> void:
	var json_str := JSON.stringify(save_data, "\t")
	# Try Steam Cloud first
	if SteamManager.is_steam_available:
		SteamManager.save_to_cloud("save_data.json", json_str)
	# Always save locally as backup
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(json_str)
	EventBus.save_completed.emit()

func load_game() -> void:
	# Try Steam Cloud first
	if SteamManager.is_steam_available:
		var cloud_data := SteamManager.load_from_cloud("save_data.json")
		if not cloud_data.is_empty():
			var parsed: Variant = JSON.parse_string(cloud_data)
			if parsed is Dictionary:
				save_data.merge(parsed, true)
				return
	# Fall back to local
	if FileAccess.file_exists(SAVE_PATH):
		var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file:
			var parsed: Variant = JSON.parse_string(file.get_as_text())
			if parsed is Dictionary:
				save_data.merge(parsed, true)

func update_best_wave(wave: int) -> void:
	if wave > save_data.get("best_wave", 0):
		save_data["best_wave"] = wave
		save_game()

func increment_runs() -> void:
	save_data["total_runs"] = save_data.get("total_runs", 0) + 1
	save_game()

func add_kills(count: int) -> void:
	save_data["total_kills"] = save_data.get("total_kills", 0) + count

func unlock_car(car_id: String) -> void:
	var unlocked: Array = save_data.get("cars_unlocked", [])
	if car_id not in unlocked:
		unlocked.append(car_id)
		save_data["cars_unlocked"] = unlocked
		save_game()

func is_car_unlocked(car_id: String) -> bool:
	return car_id in save_data.get("cars_unlocked", [])

func get_setting(key: String, default: Variant = null) -> Variant:
	return save_data.get("settings", {}).get(key, default)

func set_setting(key: String, value: Variant) -> void:
	if not save_data.has("settings"):
		save_data["settings"] = {}
	save_data["settings"][key] = value
	save_game()
