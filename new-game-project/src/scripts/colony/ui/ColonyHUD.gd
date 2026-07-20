## ColonyHUD script. does game stuff in a simple way.
extends CanvasLayer
class_name ColonyHUD

# Colony mode HUD, built entirely in code so no .tscn editing is needed.
# Top bar: speed controls, clock, entropy, resources. Bottom-left: selected
# colonist inspector. Center: event toasts and the game over overlay.
# Buttons are 44px+ so Xogot / touch play works.

const BTN_SIZE := Vector2(48, 44)

var _speed_buttons: Array[Button] = []
var _clock_label: Label
var _entropy_bar: ProgressBar
var _resources_label: Label
var _toast_label: Label
var _game_over_panel: PanelContainer

var _inspector: PanelContainer
var _pawn_name_label: Label
var _pawn_state_label: Label
var _need_bars: Dictionary = {}

var _selected_pawn: Node2D = null

func _ready():
	layer = 10
	_build_top_bar()
	_build_inspector()
	_build_toast()
	_build_game_over()
	EventBus.colony_resources_changed.connect(_on_resources_changed)
	EventBus.entropy_changed.connect(_on_entropy_changed)
	EventBus.cosmology_event.connect(_on_cosmology_event)
	EventBus.colonist_selected.connect(_on_colonist_selected)
	EventBus.colony_game_over.connect(_on_game_over)
	SimClock.speed_changed.connect(_on_speed_changed)
	_on_speed_changed(SimClock.speed_index)

func _process(_delta: float):
	_clock_label.text = "Day %d  %02d:00" % [SimClock.get_day(), SimClock.get_hour()]
	_refresh_inspector()

# --- build UI ---

# Top bar with speed buttons, clock, entropy and resources
func _build_top_bar() -> void:
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	panel.add_child(row)

	var labels := ["II", "1x", "2x", "3x"]
	for i in range(labels.size()):
		var btn := Button.new()
		btn.text = labels[i]
		btn.custom_minimum_size = BTN_SIZE
		btn.toggle_mode = true
		btn.pressed.connect(func(): SimClock.set_speed(i))
		row.add_child(btn)
		_speed_buttons.append(btn)

	_clock_label = Label.new()
	_clock_label.custom_minimum_size = Vector2(120, 0)
	_clock_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(_clock_label)

	var entropy_title := Label.new()
	entropy_title.text = "Entropy"
	entropy_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(entropy_title)

	_entropy_bar = ProgressBar.new()
	_entropy_bar.min_value = 0.0
	_entropy_bar.max_value = 100.0
	_entropy_bar.custom_minimum_size = Vector2(140, 20)
	_entropy_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_entropy_bar)

	_resources_label = Label.new()
	_resources_label.text = "Food 10   Wood 0   Exotic 0"
	_resources_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_resources_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(_resources_label)

	var menu_btn := Button.new()
	menu_btn.text = "Menu"
	menu_btn.custom_minimum_size = BTN_SIZE
	menu_btn.pressed.connect(_on_menu_pressed)
	row.add_child(menu_btn)

# Bottom-left selected pawn inspector
func _build_inspector() -> void:
	_inspector = PanelContainer.new()
	_inspector.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_inspector.offset_top = -150.0
	_inspector.offset_bottom = -8.0
	_inspector.offset_left = 8.0
	_inspector.custom_minimum_size = Vector2(220, 0)
	_inspector.visible = false
	add_child(_inspector)

	var box := VBoxContainer.new()
	_inspector.add_child(box)
	_pawn_name_label = Label.new()
	box.add_child(_pawn_name_label)
	_pawn_state_label = Label.new()
	box.add_child(_pawn_state_label)
	for need in ["health", "hunger", "rest", "mood"]:
		var need_row := HBoxContainer.new()
		box.add_child(need_row)
		var lbl := Label.new()
		lbl.text = need.capitalize()
		lbl.custom_minimum_size = Vector2(60, 0)
		need_row.add_child(lbl)
		var bar := ProgressBar.new()
		bar.min_value = 0.0
		bar.max_value = 100.0
		bar.custom_minimum_size = Vector2(130, 14)
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		bar.show_percentage = false
		need_row.add_child(bar)
		_need_bars[need] = bar

# Center-top toast for cosmology events and raids
func _build_toast() -> void:
	_toast_label = Label.new()
	_toast_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_toast_label.offset_top = 56.0
	_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast_label.modulate.a = 0.0
	_toast_label.add_theme_font_size_override("font_size", 20)
	add_child(_toast_label)

# Hidden game over overlay
func _build_game_over() -> void:
	_game_over_panel = PanelContainer.new()
	_game_over_panel.set_anchors_preset(Control.PRESET_CENTER)
	_game_over_panel.visible = false
	add_child(_game_over_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	_game_over_panel.add_child(box)
	var title := Label.new()
	title.name = "Title"
	title.text = "The colony has fallen."
	title.add_theme_font_size_override("font_size", 26)
	box.add_child(title)
	var btn := Button.new()
	btn.text = "Back to Menu"
	btn.custom_minimum_size = Vector2(160, 44)
	btn.pressed.connect(_on_menu_pressed)
	box.add_child(btn)

# --- signal handlers ---

func _on_speed_changed(index: int) -> void:
	for i in range(_speed_buttons.size()):
		_speed_buttons[i].button_pressed = (i == index)

func _on_resources_changed(amounts: Dictionary) -> void:
	_resources_label.text = "Food %d   Wood %d   Exotic %d" % [
		int(amounts.get("food", 0)), int(amounts.get("wood", 0)), int(amounts.get("exotic", 0))]

func _on_entropy_changed(value: float) -> void:
	_entropy_bar.value = value

func _on_cosmology_event(event_name: String, _pos: Vector2) -> void:
	_toast_label.text = event_name
	_toast_label.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_interval(2.0)
	tween.tween_property(_toast_label, "modulate:a", 0.0, 1.0)

func _on_colonist_selected(pawn: Node2D) -> void:
	_selected_pawn = pawn
	_inspector.visible = pawn != null

func _on_game_over(day: int) -> void:
	var title: Label = _game_over_panel.get_child(0).get_child(0)
	title.text = "The colony has fallen.\nEntropy won on day %d." % day
	_game_over_panel.visible = true

func _on_menu_pressed() -> void:
	SimClock.stop()
	get_tree().change_scene_to_file("res://src/scenes/UI/StartMenu.tscn")

# Keep the inspector bars live for the selected pawn
func _refresh_inspector() -> void:
	if _selected_pawn == null or not is_instance_valid(_selected_pawn):
		_inspector.visible = false
		return
	_pawn_name_label.text = _selected_pawn.pawn_name
	_pawn_state_label.text = "State: " + _selected_pawn.get_state_name()
	_need_bars["health"].value = 100.0 * float(_selected_pawn.health) / float(_selected_pawn.max_health)
	_need_bars["hunger"].value = _selected_pawn.needs.hunger
	_need_bars["rest"].value = _selected_pawn.needs.rest
	_need_bars["mood"].value = _selected_pawn.needs.mood
