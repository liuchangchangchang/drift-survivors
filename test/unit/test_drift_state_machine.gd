extends GutTest

var _dsm: DriftStateMachine
var _stage_changes: Array = []

func before_each():
	_dsm = DriftStateMachine.new()
	_stage_changes.clear()
	_dsm.drift_stage_changed.connect(_on_stage_changed)
	add_child_autofree(_dsm)

func _on_stage_changed(stage: int) -> void:
	_stage_changes.append(stage)

func test_initial_state_is_none():
	assert_eq(_dsm.current_stage, DriftStateMachine.DriftStage.NONE)
	assert_false(_dsm.is_drifting)

func test_start_drift_sets_charging_1():
	_dsm.start_drift()
	assert_eq(_dsm.current_stage, DriftStateMachine.DriftStage.CHARGING_1)
	assert_true(_dsm.is_drifting)

func test_start_drift_emits_signal():
	_dsm.start_drift()
	assert_eq(_stage_changes.size(), 1)
	assert_eq(_stage_changes[0], DriftStateMachine.DriftStage.CHARGING_1)

func test_double_start_ignored():
	_dsm.start_drift()
	_dsm.start_drift()
	assert_eq(_stage_changes.size(), 1, "Should not emit twice")

func test_update_to_stage_2():
	_dsm.start_drift()
	_dsm.update_drift(1.6)  # Past STAGE_2_THRESHOLD (1.5s)
	assert_eq(_dsm.current_stage, DriftStateMachine.DriftStage.CHARGING_2)

func test_update_to_ready():
	_dsm.start_drift()
	_dsm.update_drift(2.6)  # Past READY_THRESHOLD (2.5s)
	assert_eq(_dsm.current_stage, DriftStateMachine.DriftStage.READY)

func test_progressive_stages():
	_dsm.start_drift()
	assert_eq(_dsm.current_stage, DriftStateMachine.DriftStage.CHARGING_1)

	_dsm.update_drift(0.6)
	assert_eq(_dsm.current_stage, DriftStateMachine.DriftStage.CHARGING_1)

	_dsm.update_drift(1.0)  # total: 1.6s
	assert_eq(_dsm.current_stage, DriftStateMachine.DriftStage.CHARGING_2)

	_dsm.update_drift(1.0)  # total: 2.6s
	assert_eq(_dsm.current_stage, DriftStateMachine.DriftStage.READY)

func test_end_drift_resets():
	_dsm.start_drift()
	_dsm.update_drift(2.6)
	var ended := _dsm.end_drift()
	assert_eq(ended, DriftStateMachine.DriftStage.READY)
	assert_eq(_dsm.current_stage, DriftStateMachine.DriftStage.NONE)
	assert_false(_dsm.is_drifting)
	assert_eq(_dsm.drift_time, 0.0)

func test_end_drift_returns_current_stage():
	_dsm.start_drift()
	_dsm.update_drift(0.3)  # Still CHARGING_1
	var ended := _dsm.end_drift()
	assert_eq(ended, DriftStateMachine.DriftStage.CHARGING_1)

func test_nitro_multiplier_none():
	assert_eq(_dsm.get_nitro_multiplier(), 0.0)

func test_nitro_multiplier_charging_1():
	_dsm.start_drift()
	assert_eq(_dsm.get_nitro_multiplier(), 1.0)

func test_nitro_multiplier_charging_2():
	_dsm.start_drift()
	_dsm.update_drift(1.6)
	assert_eq(_dsm.get_nitro_multiplier(), 1.5)

func test_nitro_multiplier_ready():
	_dsm.start_drift()
	_dsm.update_drift(2.6)
	assert_eq(_dsm.get_nitro_multiplier(), 2.5)

func test_update_without_drifting_is_noop():
	_dsm.update_drift(5.0)
	assert_eq(_dsm.current_stage, DriftStateMachine.DriftStage.NONE)
