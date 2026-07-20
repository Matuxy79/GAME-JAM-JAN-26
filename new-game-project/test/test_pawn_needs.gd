extends GutTest

# Test suite for the PawnNeeds model
# Covers decay, thresholds, starvation, eating, sleeping and time dilation

const NEEDS_DEF := {
	"hunger_decay_per_tick": 1.0,
	"rest_decay_per_tick": 0.5,
	"hunger_eat_threshold": 35.0,
	"rest_sleep_threshold": 25.0,
	"starvation_damage_per_tick": 0.5,
	"eat_restore": 70.0,
	"sleep_restore_per_tick": 2.0
}

var needs: PawnNeeds

func before_each():
	needs = PawnNeeds.new()
	needs.configure(NEEDS_DEF)

func test_decay():
	"""Needs should fall by their per-tick rates"""
	needs.tick()
	assert_eq(needs.hunger, 99.0, "Hunger should drop by 1 per tick")
	assert_eq(needs.rest, 99.5, "Rest should drop by 0.5 per tick")

func test_hungry_threshold():
	"""is_hungry flips once hunger crosses the threshold"""
	assert_false(needs.is_hungry(), "Fresh pawn should not be hungry")
	needs.hunger = 35.0
	assert_true(needs.is_hungry(), "At the threshold the pawn is hungry")

func test_exhausted_threshold():
	"""is_exhausted flips once rest crosses the threshold"""
	assert_false(needs.is_exhausted(), "Fresh pawn should not be exhausted")
	needs.rest = 20.0
	assert_true(needs.is_exhausted(), "Below the threshold the pawn is exhausted")

func test_starvation_damage():
	"""Zero hunger deals starvation damage each tick"""
	needs.hunger = 0.5
	var damage_first = needs.tick()
	assert_eq(damage_first, 0.5, "Hunger hits zero this tick, so damage applies")
	var damage_second = needs.tick()
	assert_eq(damage_second, 0.5, "Still starving, still taking damage")

func test_eat_restores():
	"""Eating restores hunger up to the cap"""
	needs.hunger = 20.0
	needs.eat()
	assert_eq(needs.hunger, 90.0, "Eating should restore 70 hunger")
	needs.eat()
	assert_eq(needs.hunger, 100.0, "Hunger caps at 100")

func test_sleep_restores():
	"""Sleep ticks restore rest up to the cap"""
	needs.rest = 10.0
	needs.sleep_tick()
	assert_eq(needs.rest, 12.0, "One sleep tick restores 2 rest")
	needs.rest = 99.5
	needs.sleep_tick()
	assert_eq(needs.rest, 100.0, "Rest caps at 100")
	assert_true(needs.is_rested(), "99+ rest counts as rested")

func test_time_dilation_slows_decay():
	"""A pawn in a dilation zone decays slower"""
	needs.tick(0.5)
	assert_eq(needs.hunger, 99.5, "Half time scale halves hunger decay")
	assert_eq(needs.rest, 99.75, "Half time scale halves rest decay")
