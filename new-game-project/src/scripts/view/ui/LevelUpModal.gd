## LevelUpModal script. does game stuff in a simple way.
extends Control
class_name LevelUpModal

# Level up pop-up. Shows perk buttons when you ding and handles pick + keyboard nav while paused.

# UI helper
const UI = preload("res://src/scripts/view/ui/UIResourceManager.gd")

# Bits in the popup
@onready var modal_panel: Panel = $Modal
@onready var perk_container: VBoxContainer = $Modal/PerkContainer

# State
var available_perks: Array = []
var perk_buttons: Array[Button] = []
var selected_index: int = 0

func _ready():
	# Still listen while paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Set styles and signals
	setup_styles()
	setup_signals()

# Make the panel look right
func setup_styles():
	if modal_panel:
		# Get a panel skin
		var style := UI.panel_style("panel_bg", Vector4(24, 24, 24, 24))
		modal_panel.add_theme_stylebox_override("panel", style)

# Hook the level-up signal
func setup_signals():
	# Listen for level up popup
	EventBus.show_level_up_modal.connect(_on_show_level_up_modal)

func _input(event):
	# Only care when showing
	if not visible:
		return
	
	# Pick current
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_select"):
		# Enter/space picks the button
		if perk_buttons.size() > 0 and selected_index >= 0 and selected_index < perk_buttons.size():
			perk_buttons[selected_index].pressed.emit()
		get_viewport().set_input_as_handled()
		return
	
	if event.is_action_pressed("ui_up"):
		# Up arrow
		selected_index = max(0, selected_index - 1)
		update_button_focus()
		get_viewport().set_input_as_handled()
		return
	
	if event.is_action_pressed("ui_down"):
		# Down arrow
		selected_index = min(perk_buttons.size() - 1, selected_index + 1)
		update_button_focus()
		get_viewport().set_input_as_handled()
		return

# Got told to show, use these perks
func _on_show_level_up_modal(perks: Array):
	available_perks = perks
	show_modal()
	populate_perks()

# Show popup and pause
func show_modal():
	visible = true
	# Pause game
	get_tree().paused = true
	# Start at first button
	selected_index = 0
	print("Level up modal shown")

# Hide popup and unpause
func hide_modal():
	visible = false
	# Resume
	get_tree().paused = false
	# Reset
	selected_index = 0
	print("Level up modal hidden")

# Fill buttons from perks
func populate_perks():
	# Clear old buttons
	for child in perk_container.get_children():
		child.queue_free()
	perk_buttons.clear()
	
	# Make a button for each perk
	for perk_name in available_perks:
		create_perk_button(perk_name)
	
	# Set focus to first button after a frame (when buttons are ready)
	call_deferred("update_button_focus")

# Make one perk button
func create_perk_button(perk_name: String):
	var perk_data = BalanceDB.get_perk_data(perk_name)
	if perk_data.is_empty():
		return
	
	var button = Button.new()
	# Show name + description
	button.text = perk_data.name + "\n" + perk_data.description
	# Keep size
	button.custom_minimum_size = Vector2(300, 60)
	# When clicked, pick this perk
	button.pressed.connect(_on_perk_selected.bind(perk_name))
	# Let keyboard move to it
	button.focus_mode = Control.FOCUS_ALL
	perk_container.add_child(button)
	perk_buttons.append(button)

# Highlight the right button
func update_button_focus():
	# Show focus on selected
	for i in range(perk_buttons.size()):
		if i == selected_index:
			# Give focus
			perk_buttons[i].grab_focus()
		else:
			# Drop focus
			perk_buttons[i].release_focus()

# When we pick a perk, tell player then hide
func _on_perk_selected(perk_name: String):
	print("Perk selected: ", perk_name)
	
	# Apply the perk to the player
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("apply_perk"):
		player.apply_perk(perk_name)
	
	# Close the modal and resume game
	hide_modal()
