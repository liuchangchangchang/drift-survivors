extends GutTest

var _car: CarController

func before_each():
	_car = CarController.new()
	_car.stats = CarStats.new()
	add_child_autofree(_car)

func test_initial_state():
	assert_true(_car.is_alive)
	assert_eq(_car.current_hp, _car.stats.max_hp)
	assert_almost_eq(_car.get_current_speed(), 0.0, 0.01)
	assert_false(_car.is_drifting)

func test_has_drift_state_machine():
	assert_not_null(_car.drift_sm)
	assert_true(_car.drift_sm is DriftStateMachine)

func test_has_nitro_system():
	assert_not_null(_car.nitro)
	assert_true(_car.nitro is NitroSystem)

func test_take_damage():
	_car.take_damage(30.0)
	assert_eq(_car.current_hp, 70.0)

func test_damage_with_armor():
	_car.stats.armor = 10.0
	_car.take_damage(30.0)
	assert_eq(_car.current_hp, 80.0)

func test_damage_below_armor_is_zero():
	_car.stats.armor = 50.0
	_car.take_damage(10.0)
	assert_eq(_car.current_hp, 100.0)

func test_die_on_zero_hp():
	_car.take_damage(200.0)
	assert_eq(_car.current_hp, 0.0)
	assert_false(_car.is_alive)

func test_no_damage_when_dead():
	_car.die()
	_car.take_damage(50.0)
	assert_eq(_car.current_hp, 0.0)

func test_heal():
	_car.take_damage(50.0)
	_car.heal(30.0)
	assert_eq(_car.current_hp, 80.0)

func test_heal_capped_at_max():
	_car.take_damage(10.0)
	_car.heal(50.0)
	assert_eq(_car.current_hp, _car.stats.max_hp)

func test_no_heal_when_dead():
	_car.die()
	_car.heal(50.0)
	assert_eq(_car.current_hp, 0.0)

func test_hp_normalized():
	_car.take_damage(25.0)
	assert_almost_eq(_car.get_hp_normalized(), 0.75, 0.001)

func test_speed_normalized_zero():
	assert_eq(_car.get_speed_normalized(), 0.0)

func test_speed_normalized():
	_car.velocity = Vector3(14.0, 0, 0)
	assert_almost_eq(_car.get_speed_normalized(), 0.5, 0.01)

func test_die_stops_car():
	_car.velocity = Vector3(15, 0, 0)
	_car.die()
	assert_almost_eq(_car.get_current_speed(), 0.0, 0.01)
	assert_eq(_car.velocity, Vector3.ZERO)

func test_nitro_configured_from_stats():
	assert_eq(_car.nitro.max_nitro, _car.stats.nitro_max)
	assert_eq(_car.nitro.accumulation_rate, _car.stats.nitro_accumulation_rate)

func test_visual_angle_initial():
	assert_eq(_car.visual_angle, 0.0)

func test_drift_charge_initial():
	assert_eq(_car.drift_charge, 0.0)
