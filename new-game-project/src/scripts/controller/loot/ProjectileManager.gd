## ProjectileManager script. does game stuff in a simple way.
extends Node
class_name ProjectileManager

# ProjectileManager - Manages projectile pooling and spawning
# Handles projectile lifecycle and cleanup

var active_projectiles: Array[Projectile] = []
var max_projectiles: int = 100

func _ready():
	print("ProjectileManager initialized")
	setup_signals()

func setup():
	print("ProjectileManager setup")
	setup_signals()

func setup_signals():
	# Connect to EventBus signals
	if not EventBus.projectile_fired.is_connected(_on_projectile_fired):
		EventBus.projectile_fired.connect(_on_projectile_fired)
	if not EventBus.game_over.is_connected(_on_game_over):
		EventBus.game_over.connect(_on_game_over)

func _on_projectile_fired(projectile: Projectile, _direction: Vector2):
	# Track active projectile
	active_projectiles.append(projectile)
	
	# Clean up if we have too many projectiles
	if active_projectiles.size() > max_projectiles:
		cleanup_oldest_projectile()

func cleanup_oldest_projectile():
	if active_projectiles.size() > 0:
		var oldest_projectile = active_projectiles[0]
		active_projectiles.erase(oldest_projectile)
		if oldest_projectile and is_instance_valid(oldest_projectile):
			Pools.return_projectile(oldest_projectile)

func _on_game_over(_final_score: int):
	# Clear all active projectiles
	for projectile in active_projectiles:
		if projectile and is_instance_valid(projectile):
			Pools.return_projectile(projectile)
	
	active_projectiles.clear()
	print("Game over, cleared all projectiles")

func get_active_projectile_count() -> int:
	return active_projectiles.size()

func get_projectiles_in_range(center: Vector2, range_distance: float) -> Array[Projectile]:
	var projectiles_in_range = []
	for projectile in active_projectiles:
		if projectile and is_instance_valid(projectile):
			if projectile.global_position.distance_to(center) <= range_distance:
				projectiles_in_range.append(projectile)
	return projectiles_in_range

func set_max_projectiles(new_max: int):
	max_projectiles = new_max
