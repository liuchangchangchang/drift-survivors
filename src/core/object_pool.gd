class_name ObjectPool
extends Node
## Generic object pool to avoid runtime allocations.

var _scene: PackedScene
var _pool: Array[Node] = []
var _max_size: int
var _active_count: int = 0

func setup(scene: PackedScene, initial_size: int = 20, max_size: int = 200) -> void:
	_scene = scene
	_max_size = max_size
	for i in initial_size:
		var obj := _create_instance()
		_pool.append(obj)

func acquire() -> Node:
	for obj in _pool:
		if not obj.visible:
			obj.visible = true
			obj.set_process(true)
			obj.set_physics_process(true)
			_active_count += 1
			return obj
	# Pool exhausted, grow if possible
	if _pool.size() < _max_size:
		var obj := _create_instance()
		_pool.append(obj)
		obj.visible = true
		obj.set_process(true)
		obj.set_physics_process(true)
		_active_count += 1
		return obj
	return null

func release(obj: Node) -> void:
	if obj == null:
		return
	obj.visible = false
	obj.set_process(false)
	obj.set_physics_process(false)
	if _active_count > 0:
		_active_count -= 1

func release_all() -> void:
	for obj in _pool:
		if obj.visible:
			release(obj)

func get_active_count() -> int:
	return _active_count

func get_pool_size() -> int:
	return _pool.size()

func _create_instance() -> Node:
	var obj := _scene.instantiate()
	obj.visible = false
	obj.set_process(false)
	obj.set_physics_process(false)
	add_child(obj)
	return obj
