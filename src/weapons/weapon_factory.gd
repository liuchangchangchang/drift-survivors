class_name WeaponFactory
extends RefCounted
## Creates weapon instances from JSON data.

## Create a WeaponBase with the given weapon ID at tier 1
static func create_weapon(weapon_id: String, tier: int = 1) -> WeaponBase:
	var weapon_json := DataLoader.get_weapon_data(weapon_id)
	if weapon_json.is_empty():
		push_warning("WeaponFactory: Unknown weapon ID: %s" % weapon_id)
		return null
	var tier_index := tier - 1  # tiers array is 0-indexed
	var weapon_data := WeaponData.from_json(weapon_json, tier_index)
	var weapon := WeaponBase.new()
	weapon.setup(weapon_data)
	weapon.name = weapon_id
	return weapon

## Check if two weapons can be merged (same ID, same tier, tier < max)
static func can_merge(weapon_a: WeaponBase, weapon_b: WeaponBase) -> bool:
	if weapon_a == null or weapon_b == null:
		return false
	if weapon_a.data == null or weapon_b.data == null:
		return false
	if weapon_a.data.id != weapon_b.data.id:
		return false
	if weapon_a.data.tier != weapon_b.data.tier:
		return false
	var weapon_json := DataLoader.get_weapon_data(weapon_a.data.id)
	return weapon_a.data.tier < WeaponData.max_tier(weapon_json)

## Merge two weapons into a higher tier. Returns the new weapon or null.
static func merge_weapons(weapon_a: WeaponBase, weapon_b: WeaponBase) -> WeaponBase:
	if not can_merge(weapon_a, weapon_b):
		return null
	var new_tier := weapon_a.data.tier + 1
	var new_weapon := create_weapon(weapon_a.data.id, new_tier)
	if new_weapon:
		EventBus.weapon_merged.emit(weapon_a.data.id, new_tier)
	return new_weapon
