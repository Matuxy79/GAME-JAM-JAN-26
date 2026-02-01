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
	setup_camera_zoom()

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

func setup_camera_zoom():
	if not camera:
		return

	# Target visible area: 1 room = 256x256 pixels
	# Room size = 256px (16 tiles * 16px)
	var target_size = Vector2(256, 256)

	# Get viewport size
	var viewport_size = get_viewport().get_visible_rect().size

	# Calculate zoom to fit target area
	# zoom > 1 = zoomed in, zoom < 1 = zoomed out
	var zoom_x = viewport_size.x / target_size.x
	var zoom_y = viewport_size.y / target_size.y

	# Use the smaller zoom to ensure entire 768x768 fits
	var zoom_value = min(zoom_x, zoom_y)

	camera.zoom = Vector2(zoom_value, zoom_value)
	print("Camera zoom set to: ", camera.zoom, " (viewport: ", viewport_size, ", target: ", target_size, ")")

func _process(_delta):
	# Update camera to follow player
	if camera and player and is_instance_valid(player):
		camera.global_position = player.global_position
