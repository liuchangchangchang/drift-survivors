class_name WeaponData
extends Resource
## Holds data for a single weapon at a specific tier.

var id: String = ""
var weapon_name: String = ""
var type: String = "ranged"       # "ranged" or "melee"
var damage_type: String = "ranged" # "ranged", "melee", "elemental"
var tier: int = 1
var damage: float = 10.0
var fire_rate: float = 0.5       # seconds between shots
var weapon_range: float = 300.0
var projectile_speed: float = 600.0
var projectile_count: int = 1
var spread_angle: float = 0.0
var piercing: int = 0
var knockback: float = 10.0
var can_be_starting_weapon: bool = true

static func from_json(weapon_json: Dictionary, tier_index: int = 0) -> WeaponData:
	var data := WeaponData.new()
	data.id = weapon_json.get("id", "")
	data.weapon_name = weapon_json.get("name", "")
	data.type = weapon_json.get("type", "ranged")
	data.damage_type = weapon_json.get("damage_type", "ranged")
	data.can_be_starting_weapon = weapon_json.get("can_be_starting_weapon", true)

	var tiers: Array = weapon_json.get("tiers", [])
	if tier_index >= 0 and tier_index < tiers.size():
		var t: Dictionary = tiers[tier_index]
		data.tier = int(t.get("tier", 1))
		data.damage = t.get("damage", 10.0)
		data.fire_rate = t.get("fire_rate", 0.5)
		data.weapon_range = t.get("range", 300.0)
		data.projectile_speed = t.get("projectile_speed", 600.0)
		data.projectile_count = int(t.get("projectile_count", 1))
		data.spread_angle = t.get("spread_angle", 0.0)
		data.piercing = int(t.get("piercing", 0))
		data.knockback = t.get("knockback", 10.0)
	return data

## Get the next tier data for this weapon (for merging)
static func get_next_tier(weapon_json: Dictionary, current_tier: int) -> WeaponData:
	var tiers: Array = weapon_json.get("tiers", [])
	for i in tiers.size():
		if int(tiers[i].get("tier", 0)) == current_tier + 1:
			return from_json(weapon_json, i)
	return null  # Max tier reached

static func max_tier(weapon_json: Dictionary) -> int:
	var tiers: Array = weapon_json.get("tiers", [])
	var max_t := 1
	for t in tiers:
		max_t = maxi(max_t, int(t.get("tier", 1)))
	return max_t
