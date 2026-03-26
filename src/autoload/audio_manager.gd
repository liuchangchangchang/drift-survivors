extends Node
## Centralized audio playback manager.
## Manages SFX and music buses.

var sfx_bus_idx: int = -1
var music_bus_idx: int = -1

func _ready() -> void:
	sfx_bus_idx = AudioServer.get_bus_index("Master")
	music_bus_idx = AudioServer.get_bus_index("Master")
	_connect_signals()

func _connect_signals() -> void:
	EventBus.weapon_fired.connect(func(_id): play_sfx("weapon_fire"))
	EventBus.enemy_killed.connect(func(_e, _p, _v): play_sfx("enemy_death"))
	EventBus.car_damaged.connect(func(_a, _s): play_sfx("car_hit"))
	EventBus.nitro_activated.connect(func(): play_sfx("nitro_boost"))
	EventBus.drift_stage_changed.connect(_on_drift_stage)
	EventBus.material_collected.connect(func(_a): play_sfx("pickup"))
	EventBus.item_purchased.connect(func(_id): play_sfx("purchase"))
	EventBus.level_up.connect(func(_l): play_sfx("level_up"))

func _on_drift_stage(stage: int) -> void:
	if stage > 0:
		play_sfx("drift")

func play_sfx(sfx_name: String) -> void:
	# Placeholder: will load and play actual audio files
	# For now, just a stub that can be connected to
	pass

func play_music(_track_name: String) -> void:
	pass

func stop_music() -> void:
	pass

func set_sfx_volume(linear: float) -> void:
	if sfx_bus_idx >= 0:
		AudioServer.set_bus_volume_db(sfx_bus_idx, linear_to_db(linear))

func set_music_volume(linear: float) -> void:
	if music_bus_idx >= 0:
		AudioServer.set_bus_volume_db(music_bus_idx, linear_to_db(linear))
