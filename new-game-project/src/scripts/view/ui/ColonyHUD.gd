## ColonyHUD script. shows colony time/resources/pawn count and live colony event log.
extends Control
class_name ColonyHUD

@onready var day_time_label: Label = $PanelContainer/MarginContainer/VBoxContainer/DayTimeLabel
@onready var resources_label: Label = $PanelContainer/MarginContainer/VBoxContainer/ResourcesLabel
@onready var pawns_label: Label = $PanelContainer/MarginContainer/VBoxContainer/PawnsLabel
@onready var event_log: RichTextLabel = $PanelContainer/MarginContainer/VBoxContainer/EventLog

var _event_lines: Array[String] = []
const MAX_EVENT_LINES := 6

func _ready():
	_setup_signals()
	_sync_initial_state()

func _setup_signals():
	if not EventBus.colony_time_updated.is_connected(_on_colony_time_updated):
		EventBus.colony_time_updated.connect(_on_colony_time_updated)
	if not EventBus.colony_resources_updated.is_connected(_on_colony_resources_updated):
		EventBus.colony_resources_updated.connect(_on_colony_resources_updated)
	if not EventBus.colony_pawn_count_changed.is_connected(_on_colony_pawn_count_changed):
		EventBus.colony_pawn_count_changed.connect(_on_colony_pawn_count_changed)
	if not EventBus.colony_event_logged.is_connected(_on_colony_event_logged):
		EventBus.colony_event_logged.connect(_on_colony_event_logged)

func _sync_initial_state():
	day_time_label.text = "Day 1 06:00"
	resources_label.text = "Food: 0  Wood: 0  Metal: 0"
	pawns_label.text = "Pawns: 0"
	event_log.text = "Events:\n- Waiting for colony simulation..."

	var colony_time = get_node_or_null("/root/ColonyTime")
	if colony_time and colony_time.has_method("get_current_time"):
		var time_data: Dictionary = colony_time.get_current_time()
		_on_colony_time_updated(time_data.get("day", 1), time_data.get("hour", 6), time_data.get("minute", 0))

	var colony_resources = get_node_or_null("/root/ColonyResources")
	if colony_resources and colony_resources.has_method("get_resources"):
		var resources: Dictionary = colony_resources.get_resources()
		_on_colony_resources_updated(resources.get("food", 0), resources.get("wood", 0), resources.get("metal", 0))

	_on_colony_pawn_count_changed(get_tree().get_nodes_in_group("pawn").size())

func _on_colony_time_updated(day: int, hour: int, minute: int):
	day_time_label.text = "Day %d %02d:%02d" % [day, hour, minute]

func _on_colony_resources_updated(food: int, wood: int, metal: int):
	resources_label.text = "Food: %d  Wood: %d  Metal: %d" % [food, wood, metal]

func _on_colony_pawn_count_changed(count: int):
	pawns_label.text = "Pawns: %d" % count

func _on_colony_event_logged(message: String):
	_event_lines.append("- " + message)
	while _event_lines.size() > MAX_EVENT_LINES:
		_event_lines.remove_at(0)
	event_log.text = "Events:\n" + "\n".join(_event_lines)
