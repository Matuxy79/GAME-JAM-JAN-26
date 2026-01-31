## World script. does game stuff in a simple way.
extends Node2D
class_name World

# World bucket. Holds player, camera, and managers.

const UI := preload("res://src/scripts/view/ui/UIResourceManager.gd")

var player: Player
var camera: Camera2D
var enemy_manager: EnemyManager
var loot_manager: LootManager
var projectile_manager: ProjectileManager
var fx_manager: FxManager

func _ready():
	print("World initialized")
	setup_scene_references()
	setup_managers()

func setup_scene_references():
	player = $Player
	camera = $Camera2D
	enemy_manager = $EnemyManager
	loot_manager = $LootManager
	projectile_manager = $ProjectileManager
	fx_manager = $FxManager

func setup_managers():
	# Configure camera to follow player (no limits - open world)
	if camera and player:
		camera.enabled = true
		camera.make_current()

func _process(_delta):
	# Update camera to follow player
	if camera and player and is_instance_valid(player):
		camera.global_position = player.global_position
