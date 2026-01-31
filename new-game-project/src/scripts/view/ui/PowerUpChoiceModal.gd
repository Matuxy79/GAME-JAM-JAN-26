## PowerUpChoiceModal script. does game stuff in a simple way.
extends Control
class_name PowerUpChoiceModal

const UI = preload("res://src/scripts/view/ui/UIResourceManager.gd")

@onready var modal_panel: Panel = $Modal
@onready var powerup_container: VBoxContainer = $Modal/PowerUpContainer
var available_powerups: Array = []
var powerup_buttons: Array[Button] = []
var selected_index: int = 0

func _ready():
	# Process input even when tree is paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	setup_styles()
	setup_signals()

func setup_styles():
	if modal_panel:
		var style := UI.panel_style("panel_bg", Vector4(24, 24, 24, 24))
		modal_panel.add_theme_stylebox_override("panel", style)

func setup_signals():
	# Connect to EventBus signals
	EventBus.show_powerup_choice_modal.connect(_on_show_powerup_choice_modal)

func _input(event):
	# Only handle input when modal is visible
	if not visible:
		return
	
	# Handle keyboard navigation
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_select"):
		# Enter or Space pressed - select current button
		if powerup_buttons.size() > 0 and selected_index >= 0 and selected_index < powerup_buttons.size():
			powerup_buttons[selected_index].pressed.emit()
		get_viewport().set_input_as_handled()
		return
	
	if event.is_action_pressed("ui_up"):
		# Arrow up - move selection up
		selected_index = max(0, selected_index - 1)
		update_button_focus()
		get_viewport().set_input_as_handled()
		return
	
	if event.is_action_pressed("ui_down"):
		# Arrow down - move selection down
		selected_index = min(powerup_buttons.size() - 1, selected_index + 1)
		update_button_focus()
		get_viewport().set_input_as_handled()
		return

func _on_show_powerup_choice_modal(powerups: Array):
	available_powerups = powerups
	show_modal()
	populate_powerups()

func show_modal():
	visible = true
	get_tree().paused = true
	selected_index = 0  # Reset selection to first button
	print("Power-up choice modal shown")

func hide_modal():
	visible = false
	get_tree().paused = false
	selected_index = 0
	print("Power-up choice modal hidden")

func populate_powerups():
	# Clear existing powerup buttons
	for child in powerup_container.get_children():
		child.queue_free()
	powerup_buttons.clear()
	
	# Create powerup selection buttons
	for powerup_name in available_powerups:
		create_powerup_button(powerup_name)
	
	# Set focus to first button after a frame (when buttons are ready)
	call_deferred("update_button_focus")

func create_powerup_button(powerup_name: String):
	var powerup_data = BalanceDB.get_powerup_data(powerup_name)
	if powerup_data.is_empty():
		return
	
	# Create a container for icon + text
	var button = Button.new()
	button.custom_minimum_size = Vector2(300, 80)
	button.pressed.connect(_on_powerup_selected.bind(powerup_name))
	button.focus_mode = Control.FOCUS_ALL  # Enable keyboard focus
	
	# Create horizontal layout for icon and text
	var hbox = HBoxContainer.new()
	hbox.custom_minimum_size = Vector2(280, 60)
	hbox.add_theme_constant_override("separation", 10)
	
	# Add weapon icon if available
	if powerup_data.has("icon"):
		var icon_texture = load(powerup_data.icon)
		if icon_texture:
			var sprite = Sprite2D.new()
			sprite.texture = icon_texture
			sprite.scale = Vector2(0.5, 0.5)  # Scale down the icon
			sprite.modulate = Color.WHITE
			hbox.add_child(sprite)
	
	# Add text container
	var text_container = VBoxContainer.new()
	text_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var name_label = Label.new()
	name_label.text = powerup_data.name
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", Color.WHITE)
	
	var desc_label = Label.new()
	desc_label.text = powerup_data.description
	desc_label.add_theme_font_size_override("font_size", 12)
	desc_label.add_theme_color_override("font_color", Color(200, 200, 200))
	
	text_container.add_child(name_label)
	text_container.add_child(desc_label)
	hbox.add_child(text_container)
	
	button.add_child(hbox)
	powerup_container.add_child(button)
	powerup_buttons.append(button)

func update_button_focus():
	# Update visual focus on buttons
	for i in range(powerup_buttons.size()):
		if i == selected_index:
			powerup_buttons[i].grab_focus()
		else:
			powerup_buttons[i].release_focus()

func _on_powerup_selected(powerup_name: String):
	print("Power-up selected: ", powerup_name)
	
	# Apply the power-up to the player
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("activate_power_mode"):
		var powerup_data = BalanceDB.get_powerup_data(powerup_name)
		player.activate_power_mode(powerup_name, powerup_data.duration)
	
	# Hide the modal
	hide_modal()
