extends GutTest

# DataLoader is an autoload, so we test it via the singleton
# These tests verify data was loaded correctly from JSON files

func test_cars_loaded():
	assert_gt(DataLoader.cars.size(), 0, "Should have loaded at least one car")

func test_car_has_required_fields():
	var car = DataLoader.cars[0]
	assert_has(car, "id")
	assert_has(car, "name")
	assert_has(car, "base_stats")

func test_car_starter_exists():
	var car = DataLoader.get_car_data("car_starter")
	assert_eq(car.get("id"), "car_starter")
	assert_eq(car.get("name"), "Rookie Racer")

func test_car_starter_stats():
	var car = DataLoader.get_car_data("car_starter")
	var stats = car.get("base_stats", {})
	assert_eq(stats.get("max_hp"), 100.0)
	assert_eq(stats.get("weapon_slots"), 4.0)

func test_weapons_loaded():
	assert_gt(DataLoader.weapons.size(), 0, "Should have loaded weapons")

func test_weapon_has_tiers():
	var weapon = DataLoader.get_weapon_data("weapon_pistol")
	assert_has(weapon, "tiers")
	assert_eq(weapon["tiers"].size(), 4, "Pistol should have 4 tiers")

func test_weapon_pistol_tier1_damage():
	var weapon = DataLoader.get_weapon_data("weapon_pistol")
	var tier1 = weapon["tiers"][0]
	assert_eq(tier1.get("damage"), 8.0)

func test_enemies_loaded():
	assert_gt(DataLoader.enemies.size(), 0, "Should have loaded enemies")

func test_enemy_basic_exists():
	var enemy = DataLoader.get_enemy_data("enemy_basic")
	assert_eq(enemy.get("name"), "Crawler")
	assert_eq(enemy.get("type"), "regular")

func test_items_loaded():
	assert_gt(DataLoader.items.size(), 0, "Should have loaded items")

func test_item_armor_plate():
	var item = DataLoader.get_item_data("item_armor_plate")
	assert_eq(item.get("name"), "Armor Plate")
	assert_eq(item.get("rarity"), "common")
	assert_has(item, "stat_modifiers")

func test_waves_loaded():
	assert_gt(DataLoader.waves.size(), 0, "Should have loaded waves")

func test_wave_1_data():
	var wave = DataLoader.get_wave_data(1)
	assert_eq(wave.get("wave_number"), 1.0)
	assert_eq(wave.get("duration_seconds"), 20.0)

func test_wave_interpolation():
	# Wave 6 is not explicitly defined, should be interpolated
	var wave = DataLoader.get_wave_data(6)
	assert_eq(wave.get("wave_number"), 6)
	assert_gt(wave.get("duration_seconds"), 20.0, "Wave 6 should last longer than wave 1")
	assert_lt(wave.get("duration_seconds"), 90.0, "Wave 6 should be shorter than wave 20")

func test_nonexistent_car_returns_empty():
	var car = DataLoader.get_car_data("nonexistent")
	assert_eq(car.size(), 0)

func test_nonexistent_weapon_returns_empty():
	var weapon = DataLoader.get_weapon_data("nonexistent")
	assert_eq(weapon.size(), 0)

func test_upgrades_loaded():
	assert_gt(DataLoader.upgrades.size(), 0, "Should have loaded upgrades")

func test_shop_pricing_loaded():
	assert_has(DataLoader.shop_pricing, "base_reroll_cost")
