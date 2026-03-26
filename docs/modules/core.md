# Core Module

## Files
- `src/core/state_machine.gd` - Generic FSM, manages State children
- `src/core/state.gd` - Base State class with enter/exit/update/physics_update/handle_input
- `src/core/object_pool.gd` - Generic node pool with acquire/release
- `src/autoload/event_bus.gd` - Global signal hub (all game signals)
- `src/autoload/data_loader.gd` - JSON data loading with typed accessors
- `src/autoload/game_manager.gd` - Game flow FSM (Menu->CarSelect->WeaponSelect->Playing->Shop->Victory/GameOver)

## StateMachine Usage
```gdscript
# Add as child node, State children are auto-registered
var sm = StateMachine.new()
sm.transition_to("StateName")  # case-insensitive
# States emit transitioned signal to request transitions
state.transitioned.emit(self, "NextStateName")
```

## ObjectPool Usage
```gdscript
var pool = ObjectPool.new()
pool.setup(packed_scene, initial_size, max_size)
var obj = pool.acquire()  # returns null if exhausted
pool.release(obj)
pool.release_all()
```

## GameManager States
MENU -> CAR_SELECT -> WEAPON_SELECT -> PLAYING -> SHOP -> PLAYING -> ... -> VICTORY
Any PLAYING state can -> GAME_OVER (on death) or PAUSED

## Tests
- test/unit/test_state_machine.gd (9 tests)
- test/unit/test_object_pool.gd (8 tests)
- test/unit/test_data_loader.gd (18 tests)
- test/unit/test_game_manager.gd (13 tests)
