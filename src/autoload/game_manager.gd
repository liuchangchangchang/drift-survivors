extends Node
## Top-level game state machine controlling the game flow.

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

var current_state: GameState = GameState.MENU
var current_wave: int = 0
var max_waves: int = 20

func change_state(new_state: GameState) -> void:
	var old_state := current_state
	current_state = new_state
	EventBus.game_state_changed.emit(old_state, new_state)

func start_new_run() -> void:
	current_wave = 0
	change_state(GameState.CAR_SELECT)

func select_car(_car_id: String) -> void:
	change_state(GameState.WEAPON_SELECT)

func select_weapon(_weapon_id: String) -> void:
	start_next_wave()

func start_next_wave() -> void:
	current_wave += 1
	change_state(GameState.PLAYING)
	EventBus.wave_started.emit(current_wave)

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
