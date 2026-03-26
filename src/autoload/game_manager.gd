extends Node
## Top-level game state machine controlling the game flow.
## Handles scene transitions between menu, selection, gameplay, and shop.

enum GameState {
	MENU,
	CAR_SELECT,
	WEAPON_SELECT,
	PLAYING,
	LEVEL_UP,
	SHOP,
	PAUSED,
	GAME_OVER,
	VICTORY,
}

const SCENE_PATHS := {
	GameState.MENU: "res://scenes/ui/main_menu.tscn",
	GameState.CAR_SELECT: "res://scenes/ui/car_select.tscn",
	GameState.WEAPON_SELECT: "res://scenes/ui/weapon_select.tscn",
}
const GAME_ARENA_PATH := "res://scenes/game/game_arena.tscn"

var current_state: GameState = GameState.MENU
var current_wave: int = 0
var max_waves: int = 20
var selected_car_id: String = "car_starter"
var selected_weapon_id: String = "weapon_pistol"

func change_state(new_state: GameState) -> void:
	var old_state := current_state
	current_state = new_state
	EventBus.game_state_changed.emit(old_state, new_state)

func start_new_run() -> void:
	current_wave = 0
	change_state(GameState.CAR_SELECT)
	_load_scene(SCENE_PATHS[GameState.CAR_SELECT])

func select_car(car_id: String) -> void:
	selected_car_id = car_id
	change_state(GameState.WEAPON_SELECT)
	_load_scene(SCENE_PATHS[GameState.WEAPON_SELECT])

func select_weapon(weapon_id: String) -> void:
	selected_weapon_id = weapon_id
	start_next_wave()

func start_next_wave() -> void:
	current_wave += 1
	change_state(GameState.PLAYING)
	EventBus.wave_started.emit(current_wave)
	if current_wave == 1:
		_load_game_arena()

func end_wave() -> void:
	EventBus.wave_ended.emit(current_wave)
	if current_wave >= max_waves:
		change_state(GameState.VICTORY)
	else:
		change_state(GameState.SHOP)

func close_shop() -> void:
	start_next_wave()

func player_died() -> void:
	change_state(GameState.GAME_OVER)

func pause_game() -> void:
	if current_state == GameState.PLAYING:
		change_state(GameState.PAUSED)

func resume_game() -> void:
	if current_state == GameState.PAUSED:
		change_state(GameState.PLAYING)

func return_to_menu() -> void:
	current_wave = 0
	change_state(GameState.MENU)
	_load_scene(SCENE_PATHS[GameState.MENU])

func _load_scene(path: String) -> void:
	if ResourceLoader.exists(path):
		get_tree().change_scene_to_file(path)

func _load_game_arena() -> void:
	if ResourceLoader.exists(GAME_ARENA_PATH):
		var arena_scene := load(GAME_ARENA_PATH)
		if arena_scene:
			var arena: Node = arena_scene.instantiate()
			arena.selected_car_id = selected_car_id
			arena.selected_weapon_id = selected_weapon_id
			get_tree().root.add_child(arena)
			# Remove current scene
			var current := get_tree().current_scene
			if current:
				current.queue_free()
			get_tree().current_scene = arena
