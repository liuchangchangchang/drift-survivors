extends GutTest

var _spawner: EnemySpawner
var _player: Node3D

func before_each():
	_spawner = EnemySpawner.new()
	_player = Node3D.new()
	_player.global_position = Vector3(75, 0, 75)
	_spawner.player = _player
	_spawner.max_enemies = 5
	add_child_autofree(_player)
	add_child_autofree(_spawner)

func test_spawn_enemy():
	var json := DataLoader.get_enemy_data("enemy_basic")
	var data := EnemyData.from_json(json)
	var enemy := _spawner.spawn_enemy(data)
	assert_not_null(enemy)
	assert_eq(_spawner.get_active_count(), 1)

func test_spawn_off_screen():
	var json := DataLoader.get_enemy_data("enemy_basic")
	var data := EnemyData.from_json(json)
	var enemy := _spawner.spawn_enemy(data)
	var dist := enemy.global_position.distance_to(_player.global_position)
	assert_gt(dist, 40.0, "Enemy should spawn far from player")

func test_max_enemies_cap():
	var json := DataLoader.get_enemy_data("enemy_basic")
	var data := EnemyData.from_json(json)
	for i in 5:
		_spawner.spawn_enemy(data)
	var extra := _spawner.spawn_enemy(data)
	assert_null(extra, "Should not spawn beyond max")
	assert_eq(_spawner.get_active_count(), 5)

func test_spawn_without_player_fails():
	_spawner.player = null
	var json := DataLoader.get_enemy_data("enemy_basic")
	var data := EnemyData.from_json(json)
	var enemy := _spawner.spawn_enemy(data)
	assert_null(enemy)

func test_on_enemy_killed():
	var json := DataLoader.get_enemy_data("enemy_basic")
	var data := EnemyData.from_json(json)
	var enemy := _spawner.spawn_enemy(data)
	_spawner.on_enemy_killed(enemy, Vector3.ZERO, 1)
	assert_eq(_spawner.get_active_count(), 0)

func test_clear_all():
	var json := DataLoader.get_enemy_data("enemy_basic")
	var data := EnemyData.from_json(json)
	_spawner.spawn_enemy(data)
	_spawner.spawn_enemy(data)
	_spawner.clear_all()
	assert_eq(_spawner.get_active_count(), 0)

func test_enemies_in_group():
	var json := DataLoader.get_enemy_data("enemy_basic")
	var data := EnemyData.from_json(json)
	_spawner.spawn_enemy(data)
	var enemies := get_tree().get_nodes_in_group("enemies")
	assert_gt(enemies.size(), 0, "Spawned enemies should be in 'enemies' group")
