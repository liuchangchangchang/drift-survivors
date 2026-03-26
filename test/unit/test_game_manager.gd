extends GutTest

# GameManager is an autoload singleton

var _state_changes: Array = []

func before_each():
	_state_changes.clear()
	EventBus.game_state_changed.connect(_on_state_changed)
	GameManager.current_wave = 0
	GameManager.current_state = GameManager.GameState.MENU

func after_each():
	if EventBus.game_state_changed.is_connected(_on_state_changed):
		EventBus.game_state_changed.disconnect(_on_state_changed)

func _on_state_changed(old_state: int, new_state: int) -> void:
	_state_changes.append({"old": old_state, "new": new_state})

func test_initial_state_is_menu():
	assert_eq(GameManager.current_state, GameManager.GameState.MENU)

func test_start_new_run_goes_to_car_select():
	GameManager.start_new_run()
	assert_eq(GameManager.current_state, GameManager.GameState.CAR_SELECT)
	assert_eq(GameManager.current_wave, 0)

func test_select_car_goes_to_weapon_select():
	GameManager.start_new_run()
	GameManager.select_car("car_starter")
	assert_eq(GameManager.current_state, GameManager.GameState.WEAPON_SELECT)

func test_select_weapon_starts_wave_1():
	GameManager.start_new_run()
	GameManager.select_car("car_starter")
	GameManager.select_weapon("weapon_pistol")
	assert_eq(GameManager.current_state, GameManager.GameState.PLAYING)
	assert_eq(GameManager.current_wave, 1)

func test_end_wave_goes_to_shop():
	GameManager.current_state = GameManager.GameState.PLAYING
	GameManager.current_wave = 1
	GameManager.end_wave()
	assert_eq(GameManager.current_state, GameManager.GameState.SHOP)

func test_end_wave_20_goes_to_victory():
	GameManager.current_state = GameManager.GameState.PLAYING
	GameManager.current_wave = 20
	GameManager.end_wave()
	assert_eq(GameManager.current_state, GameManager.GameState.VICTORY)

func test_close_shop_starts_next_wave():
	GameManager.current_state = GameManager.GameState.SHOP
	GameManager.current_wave = 5
	GameManager.close_shop()
	assert_eq(GameManager.current_state, GameManager.GameState.PLAYING)
	assert_eq(GameManager.current_wave, 6)

func test_player_died_goes_to_game_over():
	GameManager.current_state = GameManager.GameState.PLAYING
	GameManager.player_died()
	assert_eq(GameManager.current_state, GameManager.GameState.GAME_OVER)

func test_pause_game():
	GameManager.current_state = GameManager.GameState.PLAYING
	GameManager.pause_game()
	assert_eq(GameManager.current_state, GameManager.GameState.PAUSED)

func test_resume_game():
	GameManager.current_state = GameManager.GameState.PAUSED
	GameManager.resume_game()
	assert_eq(GameManager.current_state, GameManager.GameState.PLAYING)

func test_return_to_menu():
	GameManager.current_state = GameManager.GameState.PLAYING
	GameManager.current_wave = 10
	GameManager.return_to_menu()
	assert_eq(GameManager.current_state, GameManager.GameState.MENU)
	assert_eq(GameManager.current_wave, 0)

func test_state_change_emits_signal():
	GameManager.change_state(GameManager.GameState.CAR_SELECT)
	assert_eq(_state_changes.size(), 1)
	assert_eq(_state_changes[0]["old"], GameManager.GameState.MENU)
	assert_eq(_state_changes[0]["new"], GameManager.GameState.CAR_SELECT)

func test_full_game_flow():
	# Menu -> Car Select -> Weapon Select -> Playing -> Shop -> Playing -> ... -> Victory
	GameManager.start_new_run()
	GameManager.select_car("car_starter")
	GameManager.select_weapon("weapon_pistol")
	assert_eq(GameManager.current_wave, 1)

	# Simulate completing waves 1-19
	for i in range(19):
		GameManager.end_wave()
		assert_eq(GameManager.current_state, GameManager.GameState.SHOP)
		GameManager.close_shop()
		assert_eq(GameManager.current_state, GameManager.GameState.PLAYING)

	# Wave 20 end -> victory
	assert_eq(GameManager.current_wave, 20)
	GameManager.end_wave()
	assert_eq(GameManager.current_state, GameManager.GameState.VICTORY)
