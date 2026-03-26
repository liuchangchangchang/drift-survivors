extends Node
## Steam SDK integration via GodotSteam GDExtension.
## Install GodotSteam from Godot Asset Library for full functionality.
## Without GodotSteam installed, all operations are no-ops.

var is_steam_available: bool = false
var steam_id: int = 0
var steam_username: String = ""

func _ready() -> void:
	_init_steam()

func _init_steam() -> void:
	# Check if Steam singleton exists (GodotSteam installed)
	if not Engine.has_singleton("Steam") and not ClassDB.class_exists("Steam"):
		push_warning("SteamManager: GodotSteam not installed. Running in offline mode.")
		is_steam_available = false
		return

	# GodotSteam is available - initialize
	# Uncomment when GodotSteam is installed:
	# var init_result = Steam.steamInitEx()
	# if init_result["status"] == 0:
	#     is_steam_available = true
	#     steam_id = Steam.getSteamID()
	#     steam_username = Steam.getPersonaName()
	#     print("Steam initialized! User: %s" % steam_username)
	# else:
	#     push_warning("Steam init failed: %s" % init_result["verbal"])
	#     is_steam_available = false
	pass

func _process(_delta: float) -> void:
	if is_steam_available:
		pass
		# Steam.run_callbacks()

## --- Achievements ---

func unlock_achievement(achievement_id: String) -> bool:
	if not is_steam_available:
		return false
	# Steam.setAchievement(achievement_id)
	# Steam.storeStats()
	EventBus.achievement_unlocked.emit(achievement_id)
	return true

func is_achievement_unlocked(_achievement_id: String) -> bool:
	if not is_steam_available:
		return false
	# return Steam.getAchievement(achievement_id)
	return false

## --- Leaderboards ---

func upload_score(_leaderboard_name: String, _score: int) -> void:
	if not is_steam_available:
		return
	# Steam.findLeaderboard(leaderboard_name)
	# Handle via signal callback

## --- Cloud Save ---

func save_to_cloud(filename: String, data: String) -> bool:
	if not is_steam_available:
		return false
	# Steam.fileWriteAsync(filename, data.to_utf8_buffer())
	return true

func load_from_cloud(_filename: String) -> String:
	if not is_steam_available:
		return ""
	# var content = Steam.fileRead(filename)
	# return content.get_string_from_utf8()
	return ""
