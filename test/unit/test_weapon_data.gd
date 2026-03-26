extends GutTest

func test_from_json_tier_1():
	var json := DataLoader.get_weapon_data("weapon_pistol")
	var data := WeaponData.from_json(json, 0)
	assert_eq(data.id, "weapon_pistol")
	assert_eq(data.weapon_name, "Auto Pistol")
	assert_eq(data.tier, 1)
	assert_eq(data.damage, 8.0)
	assert_eq(data.fire_rate, 0.5)

func test_from_json_tier_4():
	var json := DataLoader.get_weapon_data("weapon_pistol")
	var data := WeaponData.from_json(json, 3)
	assert_eq(data.tier, 4)
	assert_eq(data.damage, 35.0)
	assert_eq(data.piercing, 2)

func test_max_tier():
	var json := DataLoader.get_weapon_data("weapon_pistol")
	assert_eq(WeaponData.max_tier(json), 4)

func test_get_next_tier():
	var json := DataLoader.get_weapon_data("weapon_pistol")
	var next := WeaponData.get_next_tier(json, 1)
	assert_not_null(next)
	assert_eq(next.tier, 2)
	assert_eq(next.damage, 14.0)

func test_get_next_tier_at_max():
	var json := DataLoader.get_weapon_data("weapon_pistol")
	var next := WeaponData.get_next_tier(json, 4)
	assert_null(next, "Should return null at max tier")

func test_shotgun_has_spread():
	var json := DataLoader.get_weapon_data("weapon_shotgun")
	var data := WeaponData.from_json(json, 0)
	assert_eq(data.projectile_count, 5)
	assert_eq(data.spread_angle, 30.0)

func test_melee_weapon_type():
	var json := DataLoader.get_weapon_data("weapon_bumper")
	var data := WeaponData.from_json(json, 0)
	assert_eq(data.type, "melee")
	assert_eq(data.damage_type, "melee")

func test_starting_weapon_flag():
	var pistol := DataLoader.get_weapon_data("weapon_pistol")
	var sniper := DataLoader.get_weapon_data("weapon_sniper")
	var d1 := WeaponData.from_json(pistol, 0)
	var d2 := WeaponData.from_json(sniper, 0)
	assert_true(d1.can_be_starting_weapon)
	assert_false(d2.can_be_starting_weapon)
