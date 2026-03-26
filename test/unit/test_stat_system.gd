extends GutTest

func test_stat_modifier_create():
	var mod := StatModifier.create("max_hp", "flat", 10.0, "item_1")
	assert_eq(mod.stat_name, "max_hp")
	assert_eq(mod.mod_type, StatModifier.ModType.FLAT)
	assert_eq(mod.value, 10.0)
	assert_eq(mod.source, "item_1")

func test_stat_modifier_percent():
	var mod := StatModifier.create("max_speed", "percent", 0.10)
	assert_eq(mod.mod_type, StatModifier.ModType.PERCENT)

func test_stat_modifier_from_dict():
	var mod := StatModifier.from_dict({"stat": "armor", "type": "flat", "value": 5}, "test")
	assert_eq(mod.stat_name, "armor")
	assert_eq(mod.value, 5.0)
	assert_eq(mod.source, "test")

func test_calculator_flat():
	var base := {"max_hp": 100.0, "armor": 0.0}
	var mods: Array[StatModifier] = [
		StatModifier.create("max_hp", "flat", 20.0),
		StatModifier.create("armor", "flat", 5.0),
	]
	var result := StatCalculator.calculate(base, mods)
	assert_eq(result["max_hp"], 120.0)
	assert_eq(result["armor"], 5.0)

func test_calculator_percent():
	var base := {"max_speed": 500.0}
	var mods: Array[StatModifier] = [
		StatModifier.create("max_speed", "percent", 0.10),
	]
	var result := StatCalculator.calculate(base, mods)
	assert_eq(result["max_speed"], 550.0)

func test_calculator_flat_then_percent():
	var base := {"max_hp": 100.0}
	var mods: Array[StatModifier] = [
		StatModifier.create("max_hp", "flat", 50.0),
		StatModifier.create("max_hp", "percent", 0.20),
	]
	var result := StatCalculator.calculate(base, mods)
	# (100 + 50) * 1.2 = 180
	assert_eq(result["max_hp"], 180.0)

func test_calculator_multiple_percents_stack():
	var base := {"max_speed": 500.0}
	var mods: Array[StatModifier] = [
		StatModifier.create("max_speed", "percent", 0.10),
		StatModifier.create("max_speed", "percent", 0.10),
	]
	var result := StatCalculator.calculate(base, mods)
	# 500 * (1 + 0.1 + 0.1) = 500 * 1.2 = 600
	assert_eq(result["max_speed"], 600.0)

func test_calculator_new_stat():
	var base := {"max_hp": 100.0}
	var mods: Array[StatModifier] = [
		StatModifier.create("luck", "flat", 0.1),
	]
	var result := StatCalculator.calculate(base, mods)
	assert_eq(result["luck"], 0.1)

func test_player_stats_set_base():
	var ps := PlayerStats.new()
	add_child_autofree(ps)
	ps.set_base_stats({"max_hp": 100.0, "max_speed": 500.0})
	assert_eq(ps.get_stat("max_hp"), 100.0)
	assert_eq(ps.get_stat("max_speed"), 500.0)

func test_player_stats_add_modifier():
	var ps := PlayerStats.new()
	add_child_autofree(ps)
	ps.set_base_stats({"max_hp": 100.0})
	ps.add_modifier(StatModifier.create("max_hp", "flat", 20.0, "test"))
	assert_eq(ps.get_stat("max_hp"), 120.0)

func test_player_stats_remove_by_source():
	var ps := PlayerStats.new()
	add_child_autofree(ps)
	ps.set_base_stats({"max_hp": 100.0})
	ps.add_modifier(StatModifier.create("max_hp", "flat", 20.0, "item_a"))
	ps.add_modifier(StatModifier.create("max_hp", "flat", 10.0, "item_b"))
	assert_eq(ps.get_stat("max_hp"), 130.0)
	ps.remove_modifiers_by_source("item_a")
	assert_eq(ps.get_stat("max_hp"), 110.0)

func test_player_stats_get_int():
	var ps := PlayerStats.new()
	add_child_autofree(ps)
	ps.set_base_stats({"weapon_slots": 4.0})
	assert_eq(ps.get_stat_int("weapon_slots"), 4)

func test_calculate_single_stat():
	var mods: Array[StatModifier] = [
		StatModifier.create("max_hp", "flat", 20.0),
		StatModifier.create("max_speed", "percent", 0.1),
		StatModifier.create("max_hp", "percent", 0.5),
	]
	var result := StatCalculator.calculate_stat(100.0, mods, "max_hp")
	# (100 + 20) * (1 + 0.5) = 180
	assert_eq(result, 180.0)
