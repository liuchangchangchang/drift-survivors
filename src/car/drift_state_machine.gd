class_name DriftStateMachine
extends Node
## Manages drift stages: NONE -> CHARGING_1 -> CHARGING_2 -> READY
## Each stage accumulates nitro at a different rate.

signal drift_stage_changed(stage: int)

enum DriftStage {
	NONE = 0,
	CHARGING_1 = 1,
	CHARGING_2 = 2,
	READY = 3,
}

const STAGE_1_THRESHOLD := 0.5   # seconds of drifting to reach stage 1
const STAGE_2_THRESHOLD := 1.5   # seconds to reach stage 2
const READY_THRESHOLD := 2.5     # seconds to reach ready

## Nitro accumulation multiplier per stage
const STAGE_MULTIPLIERS := {
	DriftStage.NONE: 0.0,
	DriftStage.CHARGING_1: 1.0,
	DriftStage.CHARGING_2: 1.5,
	DriftStage.READY: 2.5,
}

var current_stage: DriftStage = DriftStage.NONE
var drift_time: float = 0.0
var is_drifting: bool = false

## Start a drift
func start_drift() -> void:
	if is_drifting:
		return
	is_drifting = true
	drift_time = 0.0
	_set_stage(DriftStage.CHARGING_1)

## Update drift (call every physics frame while drifting)
func update_drift(delta: float) -> void:
	if not is_drifting:
		return
	drift_time += delta
	if drift_time >= READY_THRESHOLD and current_stage != DriftStage.READY:
		_set_stage(DriftStage.READY)
	elif drift_time >= STAGE_2_THRESHOLD and current_stage == DriftStage.CHARGING_1:
		_set_stage(DriftStage.CHARGING_2)

## End the drift. Returns the stage at which drift ended.
func end_drift() -> DriftStage:
	var ended_stage := current_stage
	is_drifting = false
	drift_time = 0.0
	_set_stage(DriftStage.NONE)
	return ended_stage

## Get the nitro accumulation multiplier for current stage
func get_nitro_multiplier() -> float:
	return STAGE_MULTIPLIERS.get(current_stage, 0.0)

func _set_stage(stage: DriftStage) -> void:
	if current_stage == stage:
		return
	current_stage = stage
	drift_stage_changed.emit(int(stage))
	EventBus.drift_stage_changed.emit(int(stage))
