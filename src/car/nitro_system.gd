class_name NitroSystem
extends Node
## Manages nitro gauge: accumulation during drift, consumption during boost.

signal nitro_changed(value: float, max_value: float)
signal boost_started
signal boost_ended

var current_nitro: float = 0.0
var max_nitro: float = 100.0
var accumulation_rate: float = 10.0
var drain_rate: float = 25.0
var is_boosting: bool = false

## Accumulate nitro (called while drifting)
func accumulate(delta: float, multiplier: float = 1.0) -> void:
	if is_boosting:
		return
	var old := current_nitro
	current_nitro = minf(current_nitro + accumulation_rate * multiplier * delta, max_nitro)
	if current_nitro != old:
		nitro_changed.emit(current_nitro, max_nitro)
		EventBus.nitro_gauge_changed.emit(current_nitro / max_nitro)

## Try to activate boost. Returns true if successful.
func try_activate() -> bool:
	if current_nitro <= 0.0 or is_boosting:
		return false
	is_boosting = true
	boost_started.emit()
	EventBus.nitro_activated.emit()
	return true

## Drain nitro (called while boosting). Returns remaining nitro.
func drain(delta: float) -> float:
	if not is_boosting:
		return current_nitro
	current_nitro = maxf(0.0, current_nitro - drain_rate * delta)
	nitro_changed.emit(current_nitro, max_nitro)
	EventBus.nitro_gauge_changed.emit(current_nitro / max_nitro)
	if current_nitro <= 0.0:
		is_boosting = false
		boost_ended.emit()
		EventBus.nitro_depleted.emit()
	return current_nitro

## Configure from CarStats
func configure(stats: CarStats) -> void:
	max_nitro = stats.nitro_max
	accumulation_rate = stats.nitro_accumulation_rate
	drain_rate = stats.nitro_drain_rate
	current_nitro = 0.0
	is_boosting = false

## Get normalized gauge value (0.0 to 1.0)
func get_gauge_normalized() -> float:
	if max_nitro <= 0.0:
		return 0.0
	return current_nitro / max_nitro

func reset() -> void:
	current_nitro = 0.0
	is_boosting = false
	nitro_changed.emit(0.0, max_nitro)
