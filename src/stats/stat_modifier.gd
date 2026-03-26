class_name StatModifier
extends RefCounted
## A single stat modification: flat addition or percentage multiplier.

enum ModType { FLAT, PERCENT }

var stat_name: String = ""
var mod_type: ModType = ModType.FLAT
var value: float = 0.0
var source: String = ""  # Where this modifier came from (item ID, upgrade ID, etc.)

static func create(stat: String, type_str: String, val: float, src: String = "") -> StatModifier:
	var mod := StatModifier.new()
	mod.stat_name = stat
	mod.mod_type = ModType.PERCENT if type_str == "percent" else ModType.FLAT
	mod.value = val
	mod.source = src
	return mod

static func from_dict(data: Dictionary, src: String = "") -> StatModifier:
	return create(
		data.get("stat", ""),
		data.get("type", "flat"),
		data.get("value", 0.0),
		src
	)
