## PauseMenu script. does game stuff in a simple way.
extends Control
class_name PauseMenu

const UI = preload("res://src/scripts/view/ui/UIResourceManager.gd")

@onready var menu_panel: Panel = $MenuPanel
@onready var resume_button: Button = $MenuPanel/VBoxContainer/ResumeButton
@onready var quit_button: Button = $MenuPanel/VBoxContainer/QuitButton

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	setup_styles()
	setup_buttons()

func setup_styles():
	if menu_panel:
		var style := UI.panel_style("panel_bg", Vector4(24, 24, 24, 24))
		menu_panel.add_theme_stylebox_override("panel", style)

func setup_buttons():
	if resume_button:
		resume_button.pressed.connect(_on_resume_pressed)
	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)

func _on_resume_pressed():
	EventBus.resume_requested.emit()

func _on_quit_pressed():
	var root = get_tree().get_first_node_in_group("game_root") if get_tree() else null
	if root and root.has_method("return_to_menu"):
		root.return_to_menu()
	else:
		if get_tree():
			get_tree().paused = false
			EventBus.game_resumed.emit()
			get_tree().change_scene_to_file("res://src/scenes/UI/StartMenu.tscn")
