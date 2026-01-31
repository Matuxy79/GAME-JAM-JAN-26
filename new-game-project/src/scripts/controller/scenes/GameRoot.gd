## GameRoot script. does game stuff in a simple way.
extends Node2D
class_name GameRoot

const START_MENU_SCENE := "res://src/scenes/UI/StartMenu.tscn"

# GameRoot - Main game controller
# Manages game state, UI, and scene transitions

var world: Node2D
var ui: CanvasLayer
var hud: Control
var level_up_modal: Control
var pause_menu: Control
var game_over: Control

var is_paused: bool = false
var game_started: bool = false

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("game_root")
	print("GameRoot initialized")
	setup_scene_references()
	setup_signals()
	start_game()

func setup_scene_references():
	world = $World
	ui = $UI
	hud = $UI/HUD
	level_up_modal = $UI/LevelUpModal
	pause_menu = $UI/PauseMenu
	game_over = $UI/GameOver

func setup_signals():
	# Connect to EventBus signals
	EventBus.game_started.connect(_on_game_started)
	EventBus.game_paused.connect(_on_game_paused)
	EventBus.game_resumed.connect(_on_game_resumed)
	EventBus.resume_requested.connect(_on_resume_requested)
	EventBus.game_over.connect(_on_game_over)
	EventBus.show_level_up_modal.connect(_on_show_level_up_modal)

func start_game():
	print("Starting game...")
	game_started = true
	EventBus.game_started.emit()

func _input(event):
	if event.is_action_pressed("pause"):
		toggle_pause()

func toggle_pause():
	if is_paused:
		resume_game()
	else:
		pause_game()

func pause_game():
	is_paused = true
	get_tree().paused = true
	pause_menu.visible = true
	EventBus.game_paused.emit()
	print("Game paused")

func resume_game():
	is_paused = false
	get_tree().paused = false
	pause_menu.visible = false
	EventBus.game_resumed.emit()
	print("Game resumed")

func _on_game_started():
	print("Game started event received")

func _on_game_paused():
	print("Game paused event received")

func _on_game_resumed():
	print("Game resumed event received")

func _on_resume_requested():
	print("Resume requested")
	if is_paused:
		resume_game()

func return_to_menu():
	print("Returning to start menu")
	is_paused = false
	get_tree().paused = false
	EventBus.game_resumed.emit()
	get_tree().change_scene_to_file(START_MENU_SCENE)

func _on_game_over(final_score: int):
	print("Game over! Final score: ", final_score)
	game_over.visible = true
	game_started = false

func _on_show_level_up_modal(perks: Array):
	print("Showing level up modal with perks: ", perks)
	level_up_modal.visible = true
