## ColonyResources script. tracks core resources and updates them as time advances.
extends Node

@export var starting_food: int = 120
@export var starting_wood: int = 80
@export var starting_metal: int = 35
@export var update_interval_minutes: int = 30

var food: int = 120
var wood: int = 80
var metal: int = 35
var colonist_count: int = 0
var _last_processed_minute: int = -1

func _ready():
	food = max(starting_food, 0)
	wood = max(starting_wood, 0)
	metal = max(starting_metal, 0)
	_setup_signals()
	_emit_resources()
	print("ColonyResources initialized")

func _setup_signals():
	if not EventBus.colony_time_updated.is_connected(_on_colony_time_updated):
		EventBus.colony_time_updated.connect(_on_colony_time_updated)
	if not EventBus.colony_pawn_count_changed.is_connected(_on_colony_pawn_count_changed):
		EventBus.colony_pawn_count_changed.connect(_on_colony_pawn_count_changed)

func _on_colony_time_updated(day: int, hour: int, minute: int):
	var absolute_minute := ((day - 1) * 24 * 60) + (hour * 60) + minute
	if absolute_minute == _last_processed_minute:
		return
	_last_processed_minute = absolute_minute

	if absolute_minute > 0 and absolute_minute % update_interval_minutes == 0:
		_apply_resource_tick()

func _on_colony_pawn_count_changed(count: int):
	colonist_count = max(count, 0)
	_emit_resources()

func _apply_resource_tick():
	var food_consumption = max(1, colonist_count)
	var wood_gain = 1 + int(colonist_count / 3)
	var metal_gain = int(colonist_count / 4)

	food = max(food - food_consumption, 0)
	wood = max(wood + wood_gain, 0)
	metal = max(metal + metal_gain, 0)

	_emit_resources()
	EventBus.colony_event_logged.emit(
		"Resource tick: -%d food, +%d wood, +%d metal." % [food_consumption, wood_gain, metal_gain]
	)

func _emit_resources():
	EventBus.colony_resources_updated.emit(food, wood, metal)

func get_resources() -> Dictionary:
	return {
		"food": food,
		"wood": wood,
		"metal": metal
	}
