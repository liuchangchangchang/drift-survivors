extends GutTest

var _nitro: NitroSystem
var _signals_received: Dictionary = {}

func before_each():
	_nitro = NitroSystem.new()
	_nitro.max_nitro = 100.0
	_nitro.accumulation_rate = 10.0
	_nitro.drain_rate = 25.0
	_signals_received.clear()
	_nitro.boost_started.connect(func(): _signals_received["boost_started"] = true)
	_nitro.boost_ended.connect(func(): _signals_received["boost_ended"] = true)
	add_child_autofree(_nitro)

func test_initial_nitro_is_zero():
	assert_eq(_nitro.current_nitro, 0.0)
	assert_false(_nitro.is_boosting)

func test_accumulate_increases_nitro():
	_nitro.accumulate(1.0)
	assert_eq(_nitro.current_nitro, 10.0)

func test_accumulate_with_multiplier():
	_nitro.accumulate(1.0, 2.0)
	assert_eq(_nitro.current_nitro, 20.0)

func test_nitro_capped_at_max():
	_nitro.accumulate(20.0)  # 200 > 100 max
	assert_eq(_nitro.current_nitro, 100.0)

func test_activate_fails_when_empty():
	assert_false(_nitro.try_activate())
	assert_false(_nitro.is_boosting)

func test_activate_succeeds_with_nitro():
	_nitro.current_nitro = 50.0
	assert_true(_nitro.try_activate())
	assert_true(_nitro.is_boosting)
	assert_true(_signals_received.has("boost_started"))

func test_activate_fails_when_already_boosting():
	_nitro.current_nitro = 80.0
	_nitro.try_activate()
	assert_false(_nitro.try_activate())  # Already boosting

func test_drain_reduces_nitro():
	_nitro.current_nitro = 50.0
	_nitro.try_activate()
	_nitro.drain(1.0)
	assert_eq(_nitro.current_nitro, 25.0)

func test_drain_not_boosting_is_noop():
	_nitro.current_nitro = 50.0
	_nitro.drain(1.0)
	assert_eq(_nitro.current_nitro, 50.0)

func test_boost_ends_when_drained():
	_nitro.current_nitro = 10.0
	_nitro.try_activate()
	_nitro.drain(1.0)  # Drains 25, only 10 available
	assert_eq(_nitro.current_nitro, 0.0)
	assert_false(_nitro.is_boosting)
	assert_true(_signals_received.has("boost_ended"))

func test_no_accumulation_while_boosting():
	_nitro.current_nitro = 50.0
	_nitro.try_activate()
	_nitro.accumulate(1.0)
	# Should still be 50 (no accumulation during boost, but drain not called)
	assert_eq(_nitro.current_nitro, 50.0)

func test_gauge_normalized():
	_nitro.current_nitro = 75.0
	assert_almost_eq(_nitro.get_gauge_normalized(), 0.75, 0.001)

func test_gauge_normalized_empty():
	assert_eq(_nitro.get_gauge_normalized(), 0.0)

func test_gauge_normalized_full():
	_nitro.current_nitro = 100.0
	assert_eq(_nitro.get_gauge_normalized(), 1.0)

func test_configure_from_stats():
	var stats := CarStats.new()
	stats.nitro_max = 150.0
	stats.nitro_accumulation_rate = 20.0
	stats.nitro_drain_rate = 40.0
	_nitro.configure(stats)
	assert_eq(_nitro.max_nitro, 150.0)
	assert_eq(_nitro.accumulation_rate, 20.0)
	assert_eq(_nitro.drain_rate, 40.0)
	assert_eq(_nitro.current_nitro, 0.0)

func test_reset():
	_nitro.current_nitro = 50.0
	_nitro.try_activate()
	_nitro.reset()
	assert_eq(_nitro.current_nitro, 0.0)
	assert_false(_nitro.is_boosting)
