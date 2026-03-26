extends GutTest

var _pool: ObjectPool
# We'll use a simple scene for testing
var _test_scene: PackedScene

func before_all():
	# Create a minimal packed scene for testing
	_test_scene = PackedScene.new()
	var node := Node2D.new()
	node.name = "PooledObject"
	_test_scene.pack(node)
	node.free()

func before_each():
	_pool = ObjectPool.new()
	add_child_autofree(_pool)

func test_setup_creates_initial_pool():
	_pool.setup(_test_scene, 5, 10)
	assert_eq(_pool.get_pool_size(), 5, "Pool should have 5 initial objects")
	assert_eq(_pool.get_active_count(), 0, "No objects should be active")

func test_acquire_returns_node():
	_pool.setup(_test_scene, 5, 10)
	var obj := _pool.acquire()
	assert_not_null(obj, "Should return a node")
	assert_true(obj.visible, "Acquired object should be visible")
	assert_eq(_pool.get_active_count(), 1)

func test_release_makes_object_available():
	_pool.setup(_test_scene, 5, 10)
	var obj := _pool.acquire()
	_pool.release(obj)
	assert_false(obj.visible, "Released object should be invisible")
	assert_eq(_pool.get_active_count(), 0)

func test_acquire_reuses_released_objects():
	_pool.setup(_test_scene, 1, 5)
	var obj1 := _pool.acquire()
	_pool.release(obj1)
	var obj2 := _pool.acquire()
	assert_eq(obj1, obj2, "Should reuse the released object")
	assert_eq(_pool.get_pool_size(), 1, "Pool size should not grow")

func test_pool_grows_when_exhausted():
	_pool.setup(_test_scene, 2, 5)
	_pool.acquire()
	_pool.acquire()
	var obj3 := _pool.acquire()
	assert_not_null(obj3, "Should grow pool and return new object")
	assert_eq(_pool.get_pool_size(), 3, "Pool should have grown")

func test_pool_returns_null_at_max():
	_pool.setup(_test_scene, 2, 2)
	_pool.acquire()
	_pool.acquire()
	var obj3 := _pool.acquire()
	assert_null(obj3, "Should return null when pool is at max")

func test_release_all():
	_pool.setup(_test_scene, 5, 10)
	_pool.acquire()
	_pool.acquire()
	_pool.acquire()
	assert_eq(_pool.get_active_count(), 3)
	_pool.release_all()
	assert_eq(_pool.get_active_count(), 0, "All objects should be released")

func test_release_null_is_safe():
	_pool.setup(_test_scene, 1, 5)
	_pool.release(null) # Should not crash
	assert_eq(_pool.get_active_count(), 0)
