extends GutTest

var _econ: EconomyManager

func before_each():
	_econ = EconomyManager.new()
	add_child_autofree(_econ)

func test_initial_materials():
	assert_eq(_econ.materials, 0)

func test_add_materials():
	_econ.add_materials(50)
	assert_eq(_econ.materials, 50)

func test_spend_materials():
	_econ.add_materials(50)
	assert_true(_econ.spend_materials(30))
	assert_eq(_econ.materials, 20)

func test_spend_fails_insufficient():
	_econ.add_materials(10)
	assert_false(_econ.spend_materials(20))
	assert_eq(_econ.materials, 10)

func test_can_afford():
	_econ.add_materials(100)
	assert_true(_econ.can_afford(50))
	assert_true(_econ.can_afford(100))
	assert_false(_econ.can_afford(101))

func test_reset():
	_econ.add_materials(100)
	_econ.reset()
	assert_eq(_econ.materials, 0)
