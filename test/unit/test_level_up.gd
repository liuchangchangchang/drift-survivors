extends GutTest

var _lum: LevelUpManager
var _level_ups: Array = []

func before_each():
	_lum = LevelUpManager.new()
	_level_ups.clear()
	_lum.level_up_ready.connect(_on_level_up)
	add_child_autofree(_lum)

func _on_level_up(level: int, choices: Array[Dictionary]) -> void:
	_level_ups.append({"level": level, "choices": choices})

func test_initial_state():
	assert_eq(_lum.current_level, 0)
	assert_eq(_lum.current_xp, 0)

func test_xp_gain():
	EventBus.xp_gained.emit(5)
	assert_eq(_lum.current_xp, 5)

func test_level_up_on_threshold():
	EventBus.xp_gained.emit(10)
	assert_eq(_lum.current_level, 1)
	assert_eq(_level_ups.size(), 1)

func test_level_up_carries_xp():
	EventBus.xp_gained.emit(15)
	assert_eq(_lum.current_level, 1)
	assert_eq(_lum.current_xp, 5)  # 15 - 10

func test_multiple_level_ups():
	EventBus.xp_gained.emit(100)
	assert_gt(_lum.current_level, 1)
	assert_eq(_level_ups.size(), _lum.current_level)

func test_choices_provided():
	EventBus.xp_gained.emit(10)
	assert_eq(_level_ups[0]["choices"].size(), 3)

func test_xp_progress():
	EventBus.xp_gained.emit(5)
	assert_almost_eq(_lum.get_xp_progress(), 0.5, 0.01)

func test_apply_upgrade():
	var stats := PlayerStats.new()
	add_child_autofree(stats)
	stats.set_base_stats({"max_hp": 100.0, "armor": 0.0})
	var upgrade := {"id": "test", "stat_modifiers": [{"stat": "armor", "type": "flat", "value": 3}]}
	_lum.current_level = 1
	_lum.apply_upgrade(upgrade, stats)
	assert_eq(stats.get_stat("armor"), 3.0)
	# +1 Max HP from level up
	assert_eq(stats.get_stat("max_hp"), 101.0)

func test_reset():
	EventBus.xp_gained.emit(50)
	_lum.reset()
	assert_eq(_lum.current_level, 0)
	assert_eq(_lum.current_xp, 0)
