extends GutTest

# Tests XP curve access via BalanceDB

func before_all():
	if not Engine.has_singleton("BalanceDB"):
		add_child_autoload("BalanceDB")

func test_xp_curve_first_level():
	var xp_needed = BalanceDB.get_xp_required_for_level(2)
	assert_eq(xp_needed, 100, "Level 2 should require 100 XP per xp_curve.json")

func test_xp_curve_out_of_bounds_defaults():
	var xp_needed = BalanceDB.get_xp_required_for_level(999)
	assert_true(xp_needed > 0, "High levels should still return a positive XP requirement")
