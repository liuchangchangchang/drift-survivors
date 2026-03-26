extends GutTest

var _mgr: WeaponMountManager

func before_each():
	_mgr = WeaponMountManager.new()
	add_child_autofree(_mgr)

func test_default_4_slots():
	assert_eq(_mgr.get_slot_count(), 4)
	assert_eq(_mgr.get_empty_slot_count(), 4)

func test_equip_weapon():
	var weapon := WeaponFactory.create_weapon("weapon_pistol", 1)
	var slot := _mgr.equip_weapon(weapon)
	assert_eq(slot, 0)
	assert_eq(_mgr.get_equipped_count(), 1)
	assert_eq(_mgr.get_empty_slot_count(), 3)

func test_equip_fills_first_empty():
	var w1 := WeaponFactory.create_weapon("weapon_pistol", 1)
	var w2 := WeaponFactory.create_weapon("weapon_shotgun", 1)
	_mgr.equip_weapon(w1)
	var slot := _mgr.equip_weapon(w2)
	assert_eq(slot, 1)

func test_equip_full_returns_negative():
	for i in 4:
		var w := WeaponFactory.create_weapon("weapon_pistol", 1)
		_mgr.equip_weapon(w)
	var extra := WeaponFactory.create_weapon("weapon_smg", 1)
	var slot := _mgr.equip_weapon(extra)
	assert_eq(slot, -1, "Should return -1 when full")
	extra.free()

func test_unequip_weapon():
	var weapon := WeaponFactory.create_weapon("weapon_pistol", 1)
	_mgr.equip_weapon(weapon)
	var removed := _mgr.unequip_weapon_at(0)
	assert_not_null(removed)
	assert_eq(_mgr.get_equipped_count(), 0)
	removed.free()

func test_add_slot():
	assert_true(_mgr.add_slot())
	assert_eq(_mgr.get_slot_count(), 5)
	assert_eq(_mgr.get_empty_slot_count(), 5)

func test_add_slot_max_6():
	_mgr.add_slot()  # 5
	assert_true(_mgr.add_slot())  # 6
	assert_false(_mgr.add_slot())  # 7 would exceed max positions
	assert_eq(_mgr.get_slot_count(), 6)

func test_weapon_summary():
	var w1 := WeaponFactory.create_weapon("weapon_pistol", 1)
	var w2 := WeaponFactory.create_weapon("weapon_shotgun", 2)
	_mgr.equip_weapon(w1)
	_mgr.equip_weapon(w2)
	var summary := _mgr.get_weapon_summary()
	assert_eq(summary.size(), 2)
	assert_eq(summary[0]["id"], "weapon_pistol")
	assert_eq(summary[0]["tier"], 1)
	assert_eq(summary[1]["id"], "weapon_shotgun")
	assert_eq(summary[1]["tier"], 2)

func test_auto_merge():
	var w1 := WeaponFactory.create_weapon("weapon_pistol", 1)
	var w2 := WeaponFactory.create_weapon("weapon_pistol", 1)
	_mgr.equip_weapon(w1)
	_mgr.equip_weapon(w2)
	var merges := _mgr.try_auto_merge()
	assert_eq(merges, 1, "Should have merged once")
	assert_eq(_mgr.get_equipped_count(), 1, "Should have one weapon after merge")
	var summary := _mgr.get_weapon_summary()
	assert_eq(summary[0]["tier"], 2, "Merged weapon should be tier 2")

func test_no_merge_different_weapons():
	var w1 := WeaponFactory.create_weapon("weapon_pistol", 1)
	var w2 := WeaponFactory.create_weapon("weapon_shotgun", 1)
	_mgr.equip_weapon(w1)
	_mgr.equip_weapon(w2)
	var merges := _mgr.try_auto_merge()
	assert_eq(merges, 0)
	assert_eq(_mgr.get_equipped_count(), 2)

func test_equip_at_specific_slot():
	var weapon := WeaponFactory.create_weapon("weapon_smg", 1)
	_mgr.equip_weapon_at(2, weapon)
	assert_eq(_mgr.get_equipped_count(), 1)
	assert_true(_mgr.mounts[0].is_empty())
	assert_true(_mgr.mounts[1].is_empty())
	assert_false(_mgr.mounts[2].is_empty())
