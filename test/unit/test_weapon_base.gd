extends GutTest

var _weapon: WeaponBase

func before_each():
	_weapon = WeaponBase.new()
	var json := DataLoader.get_weapon_data("weapon_pistol")
	var data := WeaponData.from_json(json, 0)
	_weapon.setup(data)
	add_child_autofree(_weapon)

func test_setup_sets_data():
	assert_not_null(_weapon.data)
	assert_eq(_weapon.data.id, "weapon_pistol")
	assert_eq(_weapon.data.damage, 8.0)

func test_effective_damage_base():
	assert_eq(_weapon.get_effective_damage(), 8.0)

func test_effective_damage_with_multiplier():
	_weapon.damage_multiplier = 1.5
	assert_almost_eq(_weapon.get_effective_damage(), 12.0, 0.001)

func test_initial_cooldown_zero():
	assert_eq(_weapon.cooldown_timer, 0.0)

func test_fire_sets_cooldown():
	_weapon.fire(Vector2.RIGHT)
	assert_gt(_weapon.cooldown_timer, 0.0, "Cooldown should be set after fire")

func test_fire_rate_multiplier():
	_weapon.fire_rate_multiplier = 2.0  # Twice as fast
	_weapon.fire(Vector2.RIGHT)
	assert_almost_eq(_weapon.cooldown_timer, 0.25, 0.001)  # 0.5 / 2.0
