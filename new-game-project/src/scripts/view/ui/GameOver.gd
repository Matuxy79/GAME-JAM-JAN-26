## GameOver script. does game stuff in a simple way.
extends Control
class_name GameOver

const UI = preload("res://src/scripts/view/ui/UIResourceManager.gd")

@onready var panel: Panel = $Panel
@onready var score_label: Label = $Panel/ScoreLabel
@onready var restart_button: Button = $Panel/RestartButton

func _ready():
	setup_styles()
	setup_buttons()
	setup_signals()

func setup_styles():
	if panel:
		var style := UI.panel_style("panel_bg", Vector4(24, 24, 24, 24))
		panel.add_theme_stylebox_override("panel", style)

func setup_buttons():
	if restart_button:
		restart_button.pressed.connect(_on_restart_pressed)

func setup_signals():
	# Connect to EventBus signals
	EventBus.game_over.connect(_on_game_over)

func _on_game_over(final_score: int):
	show_game_over(final_score)

func show_game_over(score: int):
	visible = true
	if score_label:
		score_label.text = "Final Score: " + str(score)
	print("Game over screen shown with score: ", score)

func _on_restart_pressed():
	print("Restart pressed")
	get_tree().reload_current_scene()
