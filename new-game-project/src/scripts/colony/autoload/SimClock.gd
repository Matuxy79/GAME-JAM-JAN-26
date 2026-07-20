## SimClock script. does game stuff in a simple way.
extends Node

# Colony sim heartbeat. Emits sim_tick at a fixed rate so all colony systems
# advance in lockstep. Speed 0 = paused, 1/2/3 = multipliers.

signal sim_tick(tick: int)
signal speed_changed(speed_index: int)
signal hour_passed(hour: int)
signal day_started(day: int)
signal night_started(day: int)

const BASE_TICKS_PER_SECOND := 10.0
const SPEED_MULTIPLIERS := [0.0, 1.0, 2.0, 3.0]
const TICKS_PER_DAY := 600
const TICKS_PER_HOUR := 25
const NIGHT_START_HOUR := 20
const DAY_START_HOUR := 6

var tick: int = 0
var speed_index: int = 1
var running: bool = false

var _accumulator: float = 0.0

func _ready():
	print("SimClock initialized")

func _process(delta: float):
	if not running:
		return
	var mult: float = SPEED_MULTIPLIERS[speed_index]
	if mult <= 0.0:
		return
	_accumulator += delta * BASE_TICKS_PER_SECOND * mult
	# Don't let a long frame dump a huge tick burst
	var steps := int(_accumulator)
	if steps > 30:
		steps = 30
		_accumulator = 0.0
	for _i in range(steps):
		tick += 1
		sim_tick.emit(tick)
		if tick % TICKS_PER_HOUR == 0:
			var hour := get_hour()
			hour_passed.emit(hour)
			if hour == NIGHT_START_HOUR:
				night_started.emit(get_day())
			elif hour == DAY_START_HOUR:
				day_started.emit(get_day())
	_accumulator -= float(steps)
	if _accumulator < 0.0:
		_accumulator = 0.0

# Start the sim fresh (colony scene calls this on load)
func start() -> void:
	tick = 0
	_accumulator = 0.0
	running = true

# Stop ticking entirely (leaving colony mode)
func stop() -> void:
	running = false

# Set speed 0..3
func set_speed(index: int) -> void:
	speed_index = clampi(index, 0, SPEED_MULTIPLIERS.size() - 1)
	speed_changed.emit(speed_index)

# Speed multiplier for smooth per-frame movement (pawns walk between ticks)
func get_speed_multiplier() -> float:
	if not running:
		return 0.0
	return SPEED_MULTIPLIERS[speed_index]

# Current in-game day (starts at day 1)
func get_day() -> int:
	@warning_ignore("integer_division")
	return tick / TICKS_PER_DAY + 1

# Hour of the in-game day (0..23)
func get_hour() -> int:
	@warning_ignore("integer_division")
	return (tick % TICKS_PER_DAY) / TICKS_PER_HOUR

# True between night start and day start
func is_night() -> bool:
	var hour := get_hour()
	return hour >= NIGHT_START_HOUR or hour < DAY_START_HOUR
