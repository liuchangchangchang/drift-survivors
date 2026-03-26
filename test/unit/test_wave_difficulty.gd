extends GutTest

func test_available_enemies_wave_1():
	var enemies := WaveDifficulty.get_available_enemies(1)
	assert_true(enemies.has("enemy_basic"), "Basic enemy available at wave 1")

func test_available_enemies_wave_5():
	var enemies := WaveDifficulty.get_available_enemies(5)
	assert_true(enemies.has("enemy_basic"))
	assert_true(enemies.has("enemy_fast"))
	assert_true(enemies.has("enemy_heavy"))

func test_no_elite_at_wave_1():
	var regulars := WaveDifficulty.get_available_regular_enemies(1)
	for id in regulars:
		var data := DataLoader.get_enemy_data(id)
		assert_ne(data.get("type"), "elite")

func test_rarity_weights_wave_1():
	var weights := WaveDifficulty.get_rarity_weights(1)
	assert_eq(weights["common"], 1.0)
	assert_eq(weights["uncommon"], 0.0)
	assert_eq(weights["rare"], 0.0)
	assert_eq(weights["legendary"], 0.0)

func test_rarity_weights_wave_5():
	var weights := WaveDifficulty.get_rarity_weights(5)
	assert_gt(weights["uncommon"], 0.0)
	assert_gt(weights["rare"], 0.0)
	assert_eq(weights["legendary"], 0.0, "No legendaries before wave 8")

func test_rarity_weights_wave_10():
	var weights := WaveDifficulty.get_rarity_weights(10)
	assert_gt(weights["uncommon"], 0.0)
	assert_gt(weights["rare"], 0.0)
	assert_gt(weights["legendary"], 0.0)

func test_wave_hp_pool_increases():
	var pool_1 := WaveDifficulty.get_wave_hp_pool(1)
	var pool_10 := WaveDifficulty.get_wave_hp_pool(10)
	assert_gt(pool_10, pool_1, "Later waves should have more total HP")
