## StartMenu script. does game stuff in a simple way.
extends Control
class_name StartMenu

# Start menu screen. Handles start/options/quit clicks and kicks off the game scene.

# Where to load the game
const GAME_SCENE_PATH := "res://src/scenes/GameRoot.tscn"

# Buttons and popup
@onready var start_button: Button = $MarginContainer/Panel/VBoxContainer/StartButton
@onready var options_button: Button = $MarginContainer/Panel/VBoxContainer/OptionsButton
@onready var quit_button: Button = $MarginContainer/Panel/VBoxContainer/QuitButton
@onready var options_dialog: AcceptDialog = $OptionsDialog

func _ready():
	# Keep menu awake
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Unpause game
	get_tree().paused = false
	# Hook buttons
	setup_buttons()

# Hook button clicks
func setup_buttons():
	# Start game
	if start_button:
		start_button.pressed.connect(_on_start_pressed)
	
	# Open options
	if options_button:
		options_button.pressed.connect(_on_options_pressed)
	
	# Quit game
	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)

# Start button
func _on_start_pressed():
	# Go to game scene
	if get_tree():
		get_tree().change_scene_to_file(GAME_SCENE_PATH)

# Options button
func _on_options_pressed():
	# Find popup if it exists
	var options_popup: Node = null
	if has_node("OptionsPopup"):
		options_popup = get_node("OptionsPopup")

	# If none, make a new one
	if options_popup == null:
		# Load options scene
		var scene := load("res://src/scenes/UI/Options.tscn")
		if scene:
			# Make it and add it
			options_popup = scene.instantiate()
			options_popup.name = "OptionsPopup"
			add_child(options_popup)
		else:
			# If load fails, warn
			push_warning("StartMenu: Failed to load Options.tscn")
			return

	# Show options
	if options_popup.has_method("popup_centered"):
		# Use built-in popup
		options_popup.popup_centered()
	elif options_dialog:
		# Last backup dialog
		options_dialog.dialog_text = "Options menu coming soon!"
		options_dialog.popup_centered()
	else:
		# No UI to show
		push_warning("StartMenu: No options UI available to show.")

# Quit button
func _on_quit_pressed():
	# Quit the game
	if get_tree():
		get_tree().quit()
