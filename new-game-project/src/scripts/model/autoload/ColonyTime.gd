## ColonyTime script. drives in-game colony clock and emits time updates.
extends Node

@export var seconds_per_game_minute: float = 0.35
@export var start_day: int = 1
@export var start_hour: int = 6
@export var start_minute: int = 0

var current_day: int = 1
var current_hour: int = 6
var current_minute: int = 0
var _time_accumulator: float = 0.0
var simulation_running: bool = false

func _ready():
	current_day = max(start_day, 1)
	current_hour = clamp(start_hour, 0, 23)
	current_minute = clamp(start_minute, 0, 59)
	_setup_signals()
	_emit_time_update()
	print("ColonyTime initialized at Day ", current_day, " ", _formatted_clock())

func _process(delta: float):
	if not simulation_running:
		return
	_time_accumulator += delta
	while _time_accumulator >= seconds_per_game_minute:
		_time_accumulator -= seconds_per_game_minute
		_advance_one_minute()

func _setup_signals():
	if not EventBus.game_started.is_connected(_on_game_started):
		EventBus.game_started.connect(_on_game_started)
	if not EventBus.game_paused.is_connected(_on_game_paused):
		EventBus.game_paused.connect(_on_game_paused)
	if not EventBus.game_resumed.is_connected(_on_game_resumed):
		EventBus.game_resumed.connect(_on_game_resumed)

func _advance_one_minute():
	current_minute += 1
	if current_minute >= 60:
		current_minute = 0
		current_hour += 1
		if current_hour >= 24:
			current_hour = 0
			current_day += 1
			EventBus.colony_event_logged.emit("Day %d started." % current_day)
	EventBus.time_of_day_changed.emit(current_hour)
	_emit_time_update()

func _emit_time_update():
	EventBus.colony_time_updated.emit(current_day, current_hour, current_minute)

func _on_game_started():
	simulation_running = true
	_time_accumulator = 0.0

func _on_game_paused():
	simulation_running = false

func _on_game_resumed():
	simulation_running = true

func get_current_time() -> Dictionary:
	return {
		"day": current_day,
		"hour": current_hour,
		"minute": current_minute
	}

func _formatted_clock() -> String:
	return "%02d:%02d" % [current_hour, current_minute]
