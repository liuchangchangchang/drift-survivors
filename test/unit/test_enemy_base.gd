extends GutTest

var _enemy: EnemyBase

func before_each():
	_enemy = EnemyBase.new()
	var json := DataLoader.get_enemy_data("enemy_basic")
	var data := EnemyData.from_json(json)
	_enemy.setup(data)
	add_child_autofree(_enemy)

func test_initial_state():
	assert_true(_enemy.is_alive)
	assert_eq(_enemy.current_hp, 20.0)

func test_take_damage():
	_enemy.take_damage(10.0)
	assert_eq(_enemy.current_hp, 10.0)

func test_die_on_zero_hp():
	_enemy.take_damage(25.0)
	assert_eq(_enemy.current_hp, 0.0)
	assert_false(_enemy.is_alive)

func test_no_damage_when_dead():
	_enemy.take_damage(25.0)
	_enemy.take_damage(10.0)
	assert_eq(_enemy.current_hp, 0.0)

func test_contact_damage():
	assert_eq(_enemy.get_contact_damage(), 5.0)

func test_reset_for_pool():
	_enemy.reset_for_pool()
	assert_false(_enemy.is_alive)
	assert_false(_enemy.visible)
	assert_null(_enemy.target)

func test_activate():
	var player := Node3D.new()
	add_child_autofree(player)
	var json := DataLoader.get_enemy_data("enemy_fast")
	var data := EnemyData.from_json(json)
	_enemy.activate(data, Vector3(5, 0, 10), player)
	assert_true(_enemy.is_alive)
	assert_true(_enemy.visible)
	assert_eq(_enemy.global_position, Vector3(5, 0, 10))
	assert_eq(_enemy.target, player)
	assert_eq(_enemy.data.id, "enemy_fast")
