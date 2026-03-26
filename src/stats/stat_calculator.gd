class_name StatCalculator
extends RefCounted
## Aggregates all stat modifiers and computes final values.
## Formula: final = (base + sum_of_flat) * (1 + sum_of_percent)

static func calculate(base_stats: Dictionary, modifiers: Array[StatModifier]) -> Dictionary:
	var flat_totals: Dictionary = {}
	var percent_totals: Dictionary = {}

	for mod in modifiers:
		if mod.mod_type == StatModifier.ModType.FLAT:
			flat_totals[mod.stat_name] = flat_totals.get(mod.stat_name, 0.0) + mod.value
		else:
			percent_totals[mod.stat_name] = percent_totals.get(mod.stat_name, 0.0) + mod.value

	var result := base_stats.duplicate(true)
	# Apply flat modifiers
	for stat_name in flat_totals:
		result[stat_name] = result.get(stat_name, 0.0) + flat_totals[stat_name]

	# Apply percent modifiers
	for stat_name in percent_totals:
		var current: float = result.get(stat_name, 0.0)
		result[stat_name] = current * (1.0 + percent_totals[stat_name])

	return result

## Calculate a single stat value
static func calculate_stat(base: float, modifiers: Array[StatModifier], stat_name: String) -> float:
	var flat := 0.0
	var percent := 0.0
	for mod in modifiers:
		if mod.stat_name != stat_name:
			continue
		if mod.mod_type == StatModifier.ModType.FLAT:
			flat += mod.value
		else:
			percent += mod.value
	return (base + flat) * (1.0 + percent)
