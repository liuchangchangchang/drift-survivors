class_name ItemRarity
extends RefCounted
## Rarity enum and weighted selection for shop items.

enum Rarity { COMMON, UNCOMMON, RARE, LEGENDARY }

const RARITY_NAMES := {
	Rarity.COMMON: "common",
	Rarity.UNCOMMON: "uncommon",
	Rarity.RARE: "rare",
	Rarity.LEGENDARY: "legendary",
}

static func from_string(s: String) -> Rarity:
	match s.to_lower():
		"common": return Rarity.COMMON
		"uncommon": return Rarity.UNCOMMON
		"rare": return Rarity.RARE
		"legendary": return Rarity.LEGENDARY
	return Rarity.COMMON

static func to_string_name(r: Rarity) -> String:
	return RARITY_NAMES.get(r, "common")

## Pick a random rarity based on weights dict {"common": 1.0, "uncommon": 0.3, ...}
static func pick_rarity(weights: Dictionary, luck: float = 0.0) -> String:
	# Luck increases rarity chances (up to 2x at 100% luck)
	var luck_mult := 1.0 + clampf(luck, 0.0, 1.0)
	var adjusted: Dictionary = {}
	adjusted["common"] = weights.get("common", 1.0)
	adjusted["uncommon"] = weights.get("uncommon", 0.0) * luck_mult
	adjusted["rare"] = weights.get("rare", 0.0) * luck_mult
	adjusted["legendary"] = weights.get("legendary", 0.0) * luck_mult

	# Roll from highest to lowest
	var roll := randf()
	if adjusted["legendary"] > 0 and roll < adjusted["legendary"]:
		return "legendary"
	roll = randf()
	if adjusted["rare"] > 0 and roll < adjusted["rare"]:
		return "rare"
	roll = randf()
	if adjusted["uncommon"] > 0 and roll < adjusted["uncommon"]:
		return "uncommon"
	return "common"

## Get all items of a given rarity
static func get_items_by_rarity(rarity: String) -> Array:
	var result: Array = []
	for item in DataLoader.items:
		if item.get("rarity") == rarity:
			result.append(item)
	return result
