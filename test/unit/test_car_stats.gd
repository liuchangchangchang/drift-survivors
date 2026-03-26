extends GutTest

func test_default_values():
	var stats := CarStats.new()
	assert_eq(stats.max_hp, 100.0)
	assert_eq(stats.max_speed, 500.0)
	assert_eq(stats.weapon_slots, 4)

func test_from_dict():
	var data := {
		"max_hp": 150.0,
		"max_speed": 600.0,
		"boost_speed": 900.0,
		"engine_power": 500.0,
		"steer_angle": 20.0,
		"traction_normal": 0.7,
		"traction_drift": 0.03,
		"slip_speed": 250.0,
		"nitro_max": 120.0,
		"weapon_slots": 6,
	}
	var stats := CarStats.from_dict(data)
	assert_eq(stats.max_hp, 150.0)
	assert_eq(stats.max_speed, 600.0)
	assert_eq(stats.boost_speed, 900.0)
	assert_eq(stats.steer_angle, 20.0)
	assert_eq(stats.traction_drift, 0.03)
	assert_eq(stats.weapon_slots, 6)

func test_from_dict_with_defaults():
	var stats := CarStats.from_dict({})
	assert_eq(stats.max_hp, 100.0)
	assert_eq(stats.max_speed, 500.0)
	assert_eq(stats.weapon_slots, 4)

func test_from_json_data():
	var car_data := DataLoader.get_car_data("car_starter")
	var base_stats: Dictionary = car_data.get("base_stats", {})
	var stats := CarStats.from_dict(base_stats)
	assert_eq(stats.max_hp, 100.0)
	assert_eq(stats.weapon_slots, 4)
	assert_eq(stats.nitro_max, 100.0)
