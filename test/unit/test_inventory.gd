extends GutTest

var _inv: Inventory

func before_each():
	_inv = Inventory.new()

func test_initially_empty():
	assert_eq(_inv.get_total_item_count(), 0)

func test_add_item():
	assert_true(_inv.add_item("item_armor_plate"))
	assert_eq(_inv.get_count("item_armor_plate"), 1)
	assert_true(_inv.has_item("item_armor_plate"))

func test_add_multiple():
	_inv.add_item("item_armor_plate")
	_inv.add_item("item_armor_plate")
	assert_eq(_inv.get_count("item_armor_plate"), 2)

func test_max_stack():
	# Armor plate has max_stack 10
	for i in 10:
		assert_true(_inv.add_item("item_armor_plate"))
	assert_false(_inv.add_item("item_armor_plate"), "Should fail at max stack")
	assert_eq(_inv.get_count("item_armor_plate"), 10)

func test_remove_item():
	_inv.add_item("item_armor_plate")
	_inv.add_item("item_armor_plate")
	assert_true(_inv.remove_item("item_armor_plate"))
	assert_eq(_inv.get_count("item_armor_plate"), 1)

func test_remove_last():
	_inv.add_item("item_armor_plate")
	_inv.remove_item("item_armor_plate")
	assert_false(_inv.has_item("item_armor_plate"))
	assert_eq(_inv.get_count("item_armor_plate"), 0)

func test_remove_nonexistent():
	assert_false(_inv.remove_item("nonexistent"))

func test_total_count():
	_inv.add_item("item_armor_plate")
	_inv.add_item("item_armor_plate")
	_inv.add_item("item_scope")
	assert_eq(_inv.get_total_item_count(), 3)

func test_clear():
	_inv.add_item("item_armor_plate")
	_inv.add_item("item_scope")
	_inv.clear()
	assert_eq(_inv.get_total_item_count(), 0)

func test_invalid_item():
	assert_false(_inv.add_item("nonexistent_item"))
