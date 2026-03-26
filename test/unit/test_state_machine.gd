extends GutTest

var _sm: StateMachine
var _state_a: State
var _state_b: State

func before_each():
	_sm = StateMachine.new()
	_state_a = State.new()
	_state_a.name = "StateA"
	_state_b = State.new()
	_state_b.name = "StateB"
	_sm.add_child(_state_a)
	_sm.add_child(_state_b)
	add_child_autofree(_sm)

func test_states_registered():
	# States are registered in _ready via add_child_autofree
	assert_eq(_sm.states.size(), 2, "Should have 2 states")
	assert_not_null(_sm.get_state("statea"))
	assert_not_null(_sm.get_state("stateb"))

func test_initial_state_null_when_not_set():
	assert_null(_sm.current_state, "No initial state set, should be null")

func test_transition_to_valid_state():
	_sm.transition_to("StateA")
	assert_eq(_sm.current_state, _state_a)

func test_transition_between_states():
	_sm.transition_to("StateA")
	assert_eq(_sm.current_state, _state_a)
	_sm.transition_to("StateB")
	assert_eq(_sm.current_state, _state_b)

func test_transition_to_same_state_ignored():
	_sm.transition_to("StateA")
	_sm.transition_to("StateA")
	assert_eq(_sm.current_state, _state_a)

func test_transition_to_invalid_state():
	_sm.transition_to("NonExistent")
	assert_null(_sm.current_state, "Should remain null for invalid state")

func test_get_state_case_insensitive():
	assert_not_null(_sm.get_state("STATEA"))
	assert_not_null(_sm.get_state("statea"))
	assert_not_null(_sm.get_state("StateA"))

func test_signal_triggers_transition():
	_sm.transition_to("StateA")
	_state_a.transitioned.emit(_state_a, "StateB")
	assert_eq(_sm.current_state, _state_b)

func test_signal_from_non_current_state_ignored():
	_sm.transition_to("StateA")
	_state_b.transitioned.emit(_state_b, "StateA")
	# Should still be StateA since signal came from StateB which is not current
	assert_eq(_sm.current_state, _state_a)
