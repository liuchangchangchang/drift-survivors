class_name WaveDifficulty
extends RefCounted
## Calculates difficulty scaling for waves.

## Get the list of enemy IDs available at the given wave
static func get_available_enemies(wave: int) -> Array[String]:
	var available: Array[String] = []
	for enemy in DataLoader.enemies:
		if int(enemy.get("min_wave", 1)) <= wave:
			available.append(enemy.get("id", ""))
	return available

## Get available regular enemies (not elite or boss)
static func get_available_regular_enemies(wave: int) -> Array[String]:
	var available: Array[String] = []
	for enemy in DataLoader.enemies:
		if enemy.get("type") == "regular" and int(enemy.get("min_wave", 1)) <= wave:
			available.append(enemy.get("id", ""))
	return available

## Calculate the total enemy HP pool for a wave (for balancing)
static func get_wave_hp_pool(wave: int) -> float:
	var wave_data := DataLoader.get_wave_data(wave)
	var duration: float = wave_data.get("duration_seconds", 30.0)
	var spawn_rate: float = wave_data.get("spawn_rate", 1.0)
	var avg_hp := _get_average_enemy_hp(wave)
	var total_spawns := duration / spawn_rate
	return total_spawns * avg_hp

static func _get_average_enemy_hp(wave: int) -> float:
	var available := get_available_regular_enemies(wave)
	if available.is_empty():
		return 20.0
	var total_hp := 0.0
	for enemy_id in available:
		var json := DataLoader.get_enemy_data(enemy_id)
		var data := EnemyData.from_json_scaled(json, wave)
		total_hp += data.max_hp
	return total_hp / available.size()

## Get item rarity weights for a given wave
static func get_rarity_weights(wave: int) -> Dictionary:
	var weights := {"common": 1.0, "uncommon": 0.0, "rare": 0.0, "legendary": 0.0}
	if wave >= 2:
		weights["uncommon"] = minf(0.6, (wave - 1) * 0.06)
	if wave >= 4:
		weights["rare"] = minf(0.25, (wave - 3) * 0.025)
	if wave >= 8:
		weights["legendary"] = minf(0.08, (wave - 7) * 0.008)
	return weights
