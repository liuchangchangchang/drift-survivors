extends GutTest

func test_can_merge_same_weapon_same_tier():
	var a := WeaponFactory.create_weapon("weapon_pistol", 1)
	var b := WeaponFactory.create_weapon("weapon_pistol", 1)
	add_child_autofree(a)
	add_child_autofree(b)
	assert_true(WeaponFactory.can_merge(a, b))

func test_cannot_merge_different_weapons():
	var a := WeaponFactory.create_weapon("weapon_pistol", 1)
	var b := WeaponFactory.create_weapon("weapon_shotgun", 1)
	add_child_autofree(a)
	add_child_autofree(b)
	assert_false(WeaponFactory.can_merge(a, b))

func test_cannot_merge_different_tiers():
	var a := WeaponFactory.create_weapon("weapon_pistol", 1)
	var b := WeaponFactory.create_weapon("weapon_pistol", 2)
	add_child_autofree(a)
	add_child_autofree(b)
	assert_false(WeaponFactory.can_merge(a, b))

func test_cannot_merge_max_tier():
	var a := WeaponFactory.create_weapon("weapon_pistol", 4)
	var b := WeaponFactory.create_weapon("weapon_pistol", 4)
	add_child_autofree(a)
	add_child_autofree(b)
	assert_false(WeaponFactory.can_merge(a, b))

func test_merge_produces_next_tier():
	var a := WeaponFactory.create_weapon("weapon_pistol", 1)
	var b := WeaponFactory.create_weapon("weapon_pistol", 1)
	add_child_autofree(a)
	add_child_autofree(b)
	var merged := WeaponFactory.merge_weapons(a, b)
	assert_not_null(merged)
	assert_eq(merged.data.tier, 2)
	assert_eq(merged.data.id, "weapon_pistol")
	assert_eq(merged.data.damage, 14.0)
	if merged:
		merged.free()

func test_merge_null_weapons():
	assert_false(WeaponFactory.can_merge(null, null))
	assert_null(WeaponFactory.merge_weapons(null, null))

func test_create_weapon_returns_weapon():
	var weapon := WeaponFactory.create_weapon("weapon_shotgun", 1)
	assert_not_null(weapon)
	assert_eq(weapon.data.id, "weapon_shotgun")
	assert_eq(weapon.data.projectile_count, 5)
	weapon.free()

func test_create_unknown_weapon():
	var weapon := WeaponFactory.create_weapon("nonexistent")
	assert_null(weapon)
