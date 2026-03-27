extends GutTest

var _drop: LootDrop
var _collected_materials: int = 0

func before_each():
	_collected_materials = 0
	for conn in EventBus.xp_gained.get_connections():
		EventBus.xp_gained.disconnect(conn["callable"])
	EventBus.material_collected.connect(_on_material)
	_drop = LootDrop.new()
	_drop.setup(5, Vector3(5, 0, 5))
	add_child_autofree(_drop)

func after_each():
	if EventBus.material_collected.is_connected(_on_material):
		EventBus.material_collected.disconnect(_on_material)

func _on_material(amount: int) -> void:
	_collected_materials += amount

func test_setup():
	assert_eq(_drop.value, 5)
	assert_eq(_drop.global_position, Vector3(5, 0, 5))
	assert_false(_drop.is_collected)
	assert_true(_drop.visible)

func test_collect():
	_drop.collect()
	assert_true(_drop.is_collected)
	assert_false(_drop.visible)
	assert_eq(_collected_materials, 5)

func test_double_collect_ignored():
	_drop.is_collected = false
	_drop.collect()
	var first := _collected_materials
	_drop.collect()
	assert_eq(_collected_materials, first, "Should only collect once")

func test_loot_spawner_spawn():
	var spawner := LootSpawner.new()
	add_child_autofree(spawner)
	var drop := spawner.spawn_drop(Vector3(2.5, 0, 2.5), 3)
	assert_not_null(drop)
	assert_eq(spawner.get_drop_count(), 1)

func test_loot_spawner_max_drops():
	var spawner := LootSpawner.new()
	add_child_autofree(spawner)
	for i in 50:
		spawner.spawn_drop(Vector3(i * 0.5, 0, 0), 1)
	assert_eq(spawner.get_drop_count(), 50)
	var extra := spawner.spawn_drop(Vector3.ZERO, 5)
	assert_null(extra, "Should return null when at max")
	assert_eq(spawner.get_drop_count(), 50)

func test_loot_spawner_clear():
	var spawner := LootSpawner.new()
	add_child_autofree(spawner)
	spawner.spawn_drop(Vector3.ZERO, 1)
	spawner.spawn_drop(Vector3(0.5, 0, 0.5), 2)
	spawner.clear_all()
	assert_eq(spawner.get_drop_count(), 0)
