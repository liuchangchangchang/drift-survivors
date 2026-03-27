extends GutTest

func test_default_values():
	var stats := CarStats.new()
	assert_eq(stats.max_hp, 100.0)
	assert_eq(stats.max_speed, 28.0)
	assert_eq(stats.weapon_slots, 4)
	assert_eq(stats.base_accel, 35.0)
	assert_eq(stats.normal_grip, 0.15)

func test_from_dict():
	var data := {
		"max_hp": 150.0,
		"max_speed": 30.0,
		"boost_speed": 45.0,
		"base_accel": 15.0,
		"friction": 0.97,
		"normal_grip": 0.12,
		"drift_grip": 0.01,
		"turn_speed_normal": 6.0,
		"turn_speed_drift": 11.0,
		"charge_rate": 35.0,
		"nitro_max": 120.0,
		"weapon_slots": 6,
	}
	var stats := CarStats.from_dict(data)
	assert_eq(stats.max_hp, 150.0)
	assert_eq(stats.max_speed, 30.0)
	assert_eq(stats.boost_speed, 45.0)
	assert_eq(stats.base_accel, 15.0)
	assert_eq(stats.drift_grip, 0.01)
	assert_eq(stats.weapon_slots, 6)

func test_from_dict_with_defaults():
	var stats := CarStats.from_dict({})
	assert_eq(stats.max_hp, 100.0)
	assert_eq(stats.max_speed, 28.0)
	assert_eq(stats.weapon_slots, 4)

func test_from_json_data():
	var car_data := DataLoader.get_car_data("car_starter")
	var base_stats: Dictionary = car_data.get("base_stats", {})
	var stats := CarStats.from_dict(base_stats)
	assert_eq(stats.max_hp, 100.0)
	assert_eq(stats.weapon_slots, 4)
	assert_eq(stats.nitro_max, 100.0)
	assert_eq(stats.base_accel, 35.0)
