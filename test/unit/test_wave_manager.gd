extends GutTest

var _wm: WaveManager

func before_each():
	_wm = WaveManager.new()
	add_child_autofree(_wm)

func test_initial_state():
	assert_false(_wm.is_active)
	assert_eq(_wm.current_wave, 0)

func test_start_wave():
	_wm.start_wave(1)
	assert_true(_wm.is_active)
	assert_eq(_wm.current_wave, 1)
	assert_eq(_wm.time_remaining, 20.0)

func test_start_wave_5():
	_wm.start_wave(5)
	assert_eq(_wm.time_remaining, 35.0)

func test_wave_duration_lookup():
	assert_eq(_wm.get_wave_duration(1), 20.0)
	assert_eq(_wm.get_wave_duration(20), 90.0)

func test_interpolated_wave_duration():
	var dur := _wm.get_wave_duration(6)
	assert_gt(dur, 20.0)
	assert_lt(dur, 90.0)

func test_get_progress_inactive():
	assert_eq(_wm.get_progress(), 0.0)

func test_stop():
	_wm.start_wave(1)
	_wm.stop()
	assert_false(_wm.is_active)
	assert_eq(_wm.time_remaining, 0.0)
