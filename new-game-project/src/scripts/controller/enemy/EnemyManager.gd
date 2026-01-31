## EnemyManager script. does game stuff in a simple way.
extends Node
class_name EnemyManager

# EnemyManager - Spawns and manages enemy pool
# Handles enemy spawning, wave management, and cleanup

@export var max_enemies: int = 50
@export var spawn_interval: float = 2.0
@export var spawn_distance: float = 300.0
@export var enemy_types: Array[String] = [
	"basic_enemy",
	"fast_enemy",
	"tank_enemy"
]

# Per-type spawn timing configuration (seconds)
@export var basic_spawn_interval: float = 10.0
@export var fast_spawn_interval: float = 20.0
@export var tank_spawn_interval: float = 30.0
@export var min_spawn_interval: float = 1.0

# Runtime timers for each enemy type
var basic_spawn_timer: float = 0.0
var fast_spawn_timer: float = 0.0
var tank_spawn_timer: float = 0.0

var spawn_timer: float = 0.0
var active_enemies: Array[Enemy] = []
var player: Node2D
const DESPAWN_DISTANCE: float = 1500.0

# Wave system variables
var current_wave: int = 1
var enemies_spawned_this_wave: int = 0
var enemies_per_wave: int = 10
var player_level: int = 1

func _ready():
	print("EnemyManager initialized")
	find_player()
	setup_signals()

func setup():
	print("EnemyManager setup")
	find_player()
	setup_signals()

func setup_signals():
	# Connect to EventBus signals
	if not EventBus.enemy_died.is_connected(_on_enemy_died):
		EventBus.enemy_died.connect(_on_enemy_died)
	if not EventBus.game_started.is_connected(_on_game_started):
		EventBus.game_started.connect(_on_game_started)
	if not EventBus.game_over.is_connected(_on_game_over):
		EventBus.game_over.connect(_on_game_over)
	if not EventBus.player_level_up.is_connected(_on_player_level_up):
		EventBus.player_level_up.connect(_on_player_level_up)

func _process(delta):
	if not player or not is_instance_valid(player):
		find_player()
		return
	
	# Calculate enemies per wave based on player level
	enemies_per_wave = 10 * player_level
	
	# Update per-type spawn timers
	basic_spawn_timer -= delta
	fast_spawn_timer -= delta
	tank_spawn_timer -= delta
	
	# Spawn enemies based on individual timers
	if active_enemies.size() < max_enemies and enemies_spawned_this_wave < enemies_per_wave:
		if basic_spawn_timer <= 0:
			spawn_enemy_by_type("basic_enemy")
			basic_spawn_timer = basic_spawn_interval
		elif fast_spawn_timer <= 0:
			spawn_enemy_by_type("fast_enemy")
			fast_spawn_timer = fast_spawn_interval
		elif tank_spawn_timer <= 0:
			spawn_enemy_by_type("tank_enemy")
			tank_spawn_timer = tank_spawn_interval
	
	# Despawn enemies too far from player
	despawn_distant_enemies()

	# Check if wave is complete
	if enemies_spawned_this_wave >= enemies_per_wave and active_enemies.is_empty():
		start_next_wave()

func find_player():
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

func spawn_enemy():
	if not player or not is_instance_valid(player):
		return
	
	# Check wave limit
	if enemies_spawned_this_wave >= enemies_per_wave:
		return
	
	# Get enemy from pool
	var enemy = Pools.get_enemy()
	if not enemy:
		return
	
	if enemy.has_method("prepare_for_spawn"):
		enemy.prepare_for_spawn()
	else:
		enemy.visible = true
		enemy.process_mode = Node.PROCESS_MODE_INHERIT
		enemy.set_process(true)
		enemy.set_physics_process(true)
	
	# Choose random enemy type
	var enemy_type = Rng.random_choice(enemy_types)
	if enemy.has_method("apply_enemy_type"):
		enemy.apply_enemy_type(enemy_type)
	else:
		enemy.enemy_type = enemy_type
	
	# Position enemy at random location around player (within viewport)
	var spawn_position = get_spawn_position()
	enemy.global_position = spawn_position
	
	# Add to scene
	get_tree().current_scene.add_child(enemy)
	active_enemies.append(enemy)
	enemies_spawned_this_wave += 1
	
	# Emit spawn event
	EventBus.enemy_spawned.emit(enemy)
	
	print("Spawned enemy: ", enemy_type, " at ", spawn_position, " (Wave ", current_wave, ", ", enemies_spawned_this_wave, "/", enemies_per_wave, ")")

func spawn_enemy_by_type(enemy_type: String):
	if not player or not is_instance_valid(player):
		return
	
	# Check wave limit
	if enemies_spawned_this_wave >= enemies_per_wave:
		return
	
	# Get enemy from pool
	var enemy = Pools.get_enemy()
	if not enemy:
		return
	
	if enemy.has_method("prepare_for_spawn"):
		enemy.prepare_for_spawn()
	else:
		enemy.visible = true
		enemy.process_mode = Node.PROCESS_MODE_INHERIT
		enemy.set_process(true)
		enemy.set_physics_process(true)
	
	# Apply the specified enemy type
	if enemy.has_method("apply_enemy_type"):
		enemy.apply_enemy_type(enemy_type)
	else:
		enemy.enemy_type = enemy_type
	
	# Position enemy at random location around player
	var spawn_position = get_spawn_position()
	enemy.global_position = spawn_position
	
	# Add to scene
	get_tree().current_scene.add_child(enemy)
	active_enemies.append(enemy)
	enemies_spawned_this_wave += 1
	
	# Emit spawn event
	EventBus.enemy_spawned.emit(enemy)
	
	print("Spawned enemy: ", enemy_type, " at ", spawn_position, " (Wave ", current_wave, ", ", enemies_spawned_this_wave, "/", enemies_per_wave, ")")

func get_spawn_position() -> Vector2:
	if not player:
		return Vector2.ZERO

	# Generate random position around player (open world - no clamping)
	var angle = Rng.randf() * 2.0 * PI
	var distance = Rng.randf_range(spawn_distance * 0.8, spawn_distance * 1.2)

	var spawn_pos = player.global_position + Vector2(cos(angle), sin(angle)) * distance

	# Make sure spawn position is not too close to player
	var min_distance = 100.0
	if spawn_pos.distance_to(player.global_position) < min_distance:
		spawn_pos = player.global_position + Vector2(cos(angle), sin(angle)) * min_distance

	return spawn_pos

func despawn_distant_enemies():
	if not player or not is_instance_valid(player):
		return

	var enemies_to_despawn: Array[Enemy] = []
	for enemy in active_enemies:
		if enemy and is_instance_valid(enemy):
			if enemy.global_position.distance_to(player.global_position) > DESPAWN_DISTANCE:
				enemies_to_despawn.append(enemy)

	for enemy in enemies_to_despawn:
		active_enemies.erase(enemy)
		Pools.return_enemy(enemy)

func _on_enemy_died(enemy: Enemy, position: Vector2):
	# Remove from active enemies list
	if enemy in active_enemies:
		active_enemies.erase(enemy)
	
	# Spawn XP gem at death location
	spawn_xp_gem(position)

func spawn_xp_gem(position: Vector2):
	var xp_gem = Pools.get_xp_gem()
	if not xp_gem:
		return
	
	xp_gem.global_position = position
	get_tree().current_scene.call_deferred("add_child", xp_gem)
	
	print("Spawned XP gem at ", position)

func _on_game_started():
	# Reset spawn timer and wave system
	spawn_timer = spawn_interval
	current_wave = 1
	enemies_spawned_this_wave = 0
	player_level = 1
	enemies_per_wave = 10 * player_level
	
	# Initialize per-type spawn timers so they don't all fire on frame 1
	basic_spawn_timer = basic_spawn_interval
	fast_spawn_timer = fast_spawn_interval
	tank_spawn_timer = tank_spawn_interval
	
	# Spawn one of each enemy type at the start of the game
	for enemy_type in enemy_types:
		spawn_enemy_by_type(enemy_type)
	
	print("Game started, enemy spawning enabled - Wave ", current_wave)

func _on_game_over(_final_score: int):
	# Clear all active enemies
	for enemy in active_enemies:
		if enemy and is_instance_valid(enemy):
			enemy.queue_free()
	active_enemies.clear()
	
	print("Game over, cleared all enemies")

func get_active_enemy_count() -> int:
	return active_enemies.size()

func get_enemies_in_range(center: Vector2, range_distance: float) -> Array[Enemy]:
	var enemies_in_range = []
	for enemy in active_enemies:
		if enemy and is_instance_valid(enemy):
			if enemy.global_position.distance_to(center) <= range_distance:
				enemies_in_range.append(enemy)
	return enemies_in_range

func set_max_enemies(new_max: int):
	max_enemies = new_max

func set_spawn_interval(new_interval: float):
	spawn_interval = new_interval

func _on_player_level_up(new_level: int):
	# Update player level and make enemies spawn faster each level
	player_level = new_level
	_update_spawn_intervals()

func _update_spawn_intervals():
	basic_spawn_interval = max(min_spawn_interval, basic_spawn_interval - 1.0)
	fast_spawn_interval = max(min_spawn_interval, fast_spawn_interval - 1.0)
	tank_spawn_interval = max(min_spawn_interval, tank_spawn_interval - 1.0)
	
	basic_spawn_timer = basic_spawn_interval
	fast_spawn_timer = fast_spawn_interval
	tank_spawn_timer = tank_spawn_interval
	
	print("Spawn intervals updated for level ", player_level, ": basic=", basic_spawn_interval, ", fast=", fast_spawn_interval, ", tank=", tank_spawn_interval)

func start_next_wave():
	# Start next wave: reset counters and update wave number
	current_wave += 1
	enemies_spawned_this_wave = 0
	enemies_per_wave = 10 * player_level
	print("Wave ", current_wave, " started - Spawning ", enemies_per_wave, " enemies")
