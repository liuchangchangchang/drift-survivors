extends Node
## Steam SDK integration via GodotSteam.
## Stub - will be fully implemented in Phase 11.

var is_steam_available: bool = false

func _ready() -> void:
	_init_steam()

func _init_steam() -> void:
	# GodotSteam will be installed later
	# For now, just mark as unavailable
	is_steam_available = false

func _process(_delta: float) -> void:
	if is_steam_available:
		pass # Steam.run_callbacks()
