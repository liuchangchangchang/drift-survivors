extends GutTest

func test_from_json():
	var json := DataLoader.get_enemy_data("enemy_basic")
	var data := EnemyData.from_json(json)
	assert_eq(data.id, "enemy_basic")
	assert_eq(data.enemy_name, "Crawler")
	assert_eq(data.type, "regular")
	assert_eq(data.max_hp, 20.0)
	assert_eq(data.speed, 80.0)
	assert_eq(data.contact_damage, 5.0)
	assert_eq(data.material_drop, 1)

func test_from_json_elite():
	var json := DataLoader.get_enemy_data("enemy_elite_brute")
	var data := EnemyData.from_json(json)
	assert_eq(data.type, "elite")
	assert_eq(data.max_hp, 100.0)
	assert_eq(data.material_drop, 5)

func test_from_json_boss():
	var json := DataLoader.get_enemy_data("enemy_boss_overlord")
	var data := EnemyData.from_json(json)
	assert_eq(data.type, "boss")
	assert_eq(data.max_hp, 2000.0)
	assert_eq(data.size, "boss")

func test_scaling_wave_1():
	var json := DataLoader.get_enemy_data("enemy_basic")
	var data := EnemyData.from_json_scaled(json, 1)
	assert_eq(data.max_hp, 20.0, "Wave 1 should have base HP")

func test_scaling_wave_10():
	var json := DataLoader.get_enemy_data("enemy_basic")
	var data := EnemyData.from_json_scaled(json, 10)
	# HP multiplier 1.15^9 = ~3.52, so 20 * 3.52 ≈ 70.4
	assert_gt(data.max_hp, 60.0, "Wave 10 HP should be much higher")
	assert_lt(data.max_hp, 80.0)

func test_scaling_speed():
	var json := DataLoader.get_enemy_data("enemy_basic")
	var data := EnemyData.from_json_scaled(json, 10)
	assert_gt(data.speed, 80.0, "Wave 10 speed should be higher than base")

func test_min_wave():
	var json := DataLoader.get_enemy_data("enemy_fast")
	var data := EnemyData.from_json(json)
	assert_eq(data.min_wave, 2)
