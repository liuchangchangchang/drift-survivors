extends GutTest
## Sanity check test to verify GUT framework is working.

func test_true_is_true():
	assert_true(true, "true should be true")

func test_basic_math():
	assert_eq(2 + 2, 4, "2 + 2 should equal 4")

func test_string_concat():
	assert_eq("hello" + " " + "world", "hello world")
