## PawnNeeds script. does game stuff in a simple way.
extends RefCounted
class_name PawnNeeds

# Pure needs model for a pawn: hunger, rest, mood. Kept scene-free so GUT
# tests can hammer it directly. All values run 0..100 (100 = fully satisfied).

var hunger: float = 100.0
var rest: float = 100.0
var mood: float = 100.0

var hunger_decay_per_tick: float = 0.0
var rest_decay_per_tick: float = 0.0
var hunger_eat_threshold: float = 0.0
var rest_sleep_threshold: float = 0.0
var starvation_damage_per_tick: float = 0.0
var eat_restore: float = 0.0
var sleep_restore_per_tick: float = 0.0

# Configure from the "needs" block of a pawn def
func configure(needs_def: Dictionary) -> void:
	hunger_decay_per_tick = float(needs_def.get("hunger_decay_per_tick", 0.0))
	rest_decay_per_tick = float(needs_def.get("rest_decay_per_tick", 0.0))
	hunger_eat_threshold = float(needs_def.get("hunger_eat_threshold", 0.0))
	rest_sleep_threshold = float(needs_def.get("rest_sleep_threshold", 0.0))
	starvation_damage_per_tick = float(needs_def.get("starvation_damage_per_tick", 0.0))
	eat_restore = float(needs_def.get("eat_restore", 0.0))
	sleep_restore_per_tick = float(needs_def.get("sleep_restore_per_tick", 0.0))

# Advance one sim tick. time_scale < 1 means the pawn lives slower
# (time dilation zone), so its needs decay slower too.
# Returns starvation damage to apply this tick (0 when fed).
func tick(time_scale: float = 1.0) -> float:
	hunger = maxf(hunger - hunger_decay_per_tick * time_scale, 0.0)
	rest = maxf(rest - rest_decay_per_tick * time_scale, 0.0)
	# Mood drifts toward the average of the other needs
	var target := (hunger + rest) / 2.0
	mood = move_toward(mood, target, 0.1 * time_scale)
	if hunger <= 0.0:
		return starvation_damage_per_tick * time_scale
	return 0.0

# True when the pawn should go find food
func is_hungry() -> bool:
	return hunger <= hunger_eat_threshold

# True when the pawn should go sleep
func is_exhausted() -> bool:
	return rest <= rest_sleep_threshold

# Eat a meal
func eat() -> void:
	hunger = minf(hunger + eat_restore, 100.0)

# One tick of sleeping
func sleep_tick(time_scale: float = 1.0) -> void:
	rest = minf(rest + sleep_restore_per_tick * time_scale, 100.0)

# True once fully rested
func is_rested() -> bool:
	return rest >= 99.0
