class_name EnemyData
extends Resource
## Holds data for an enemy type at a specific wave.

var id: String = ""
var enemy_name: String = ""
var type: String = "regular"  # "regular", "elite", "boss"
var size: String = "small"
var max_hp: float = 20.0
var speed: float = 80.0
var contact_damage: float = 5.0
var material_drop: int = 1
var min_wave: int = 1

static func from_json(data: Dictionary) -> EnemyData:
	var ed := EnemyData.new()
	ed.id = data.get("id", "")
	ed.enemy_name = data.get("name", "")
	ed.type = data.get("type", "regular")
	ed.size = data.get("size", "small")
	ed.min_wave = int(data.get("min_wave", 1))
	var base: Dictionary = data.get("base_stats", {})
	ed.max_hp = base.get("max_hp", 20.0)
	ed.speed = base.get("speed", 80.0)
	ed.contact_damage = base.get("contact_damage", 5.0)
	ed.material_drop = int(base.get("material_drop", 1))
	return ed

## Scale stats for a given wave number
static func from_json_scaled(data: Dictionary, wave: int) -> EnemyData:
	var ed := from_json(data)
	var scale: Dictionary = data.get("scale_per_wave", {})
	var waves_past_first := maxi(0, wave - 1)
	ed.max_hp *= pow(scale.get("hp_multiplier", 1.0), waves_past_first)
	ed.speed *= pow(scale.get("speed_multiplier", 1.0), waves_past_first)
	ed.contact_damage *= pow(scale.get("damage_multiplier", 1.0), waves_past_first)
	return ed
