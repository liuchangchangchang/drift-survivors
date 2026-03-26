class_name PlayerStats
extends Node
## Central stat store. Aggregates base car stats + all modifiers from items/upgrades.

var base_stats: Dictionary = {}
var modifiers: Array[StatModifier] = []
var final_stats: Dictionary = {}

func set_base_stats(stats: Dictionary) -> void:
	base_stats = stats.duplicate(true)
	recalculate()

func add_modifier(mod: StatModifier) -> void:
	modifiers.append(mod)
	recalculate()

func add_modifiers_from_dict_array(mod_array: Array, source: String) -> void:
	for mod_data in mod_array:
		var mod := StatModifier.from_dict(mod_data, source)
		modifiers.append(mod)
	recalculate()

func remove_modifiers_by_source(source: String) -> void:
	modifiers = modifiers.filter(func(m): return m.source != source)
	recalculate()

func recalculate() -> void:
	var old_stats := final_stats.duplicate()
	final_stats = StatCalculator.calculate(base_stats, modifiers)
	# Emit signals for changed stats
	for key in final_stats:
		var old_val: float = old_stats.get(key, 0.0)
		var new_val: float = final_stats.get(key, 0.0)
		if absf(old_val - new_val) > 0.001:
			EventBus.stat_changed.emit(key, old_val, new_val)

func get_stat(stat_name: String, default: float = 0.0) -> float:
	return final_stats.get(stat_name, default)

func get_stat_int(stat_name: String, default: int = 0) -> int:
	return int(final_stats.get(stat_name, float(default)))

func clear() -> void:
	modifiers.clear()
	base_stats.clear()
	final_stats.clear()
