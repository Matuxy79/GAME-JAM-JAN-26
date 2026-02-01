## Enemy - Walk to decor and stand (no player attacking)
extends CharacterBody2D
class_name Enemy

# Enemy AI: Find decor, walk to it, stand there
# Enemies do NOT chase or attack the player

enum State {
	IDLE,           # Looking for decor to claim
	WALK_TO_DECOR,  # Walking toward claimed decor
	STANDING,       # At decor, just standing
	DYING
}

@export var enemy_type: String = "elephant"
@export var max_health: int = 50
@export var speed: float = 12.0
@export var xp_reward: int = 25

var current_health: int
var current_state: State = State.IDLE
var claimed_decor_pos: Vector2 = Vector2.INF
var world_map: Node  # Reference to WorldMap for decor claiming
var knockback_velocity: Vector2 = Vector2.ZERO

# Animal sprite textures
const ANIMAL_SPRITES = {
	"elephant": preload("res://assets/sprites/enemies/new-to-replace-old/elephant.png"),
	"giraffe": preload("res://assets/sprites/enemies/new-to-replace-old/giraffe.png"),
	"hippo": preload("res://assets/sprites/enemies/new-to-replace-old/hippo.png"),
	"monkey": preload("res://assets/sprites/enemies/new-to-replace-old/monkey.png"),
	"panda": preload("res://assets/sprites/enemies/new-to-replace-old/panda.png"),
	"parrot": preload("res://assets/sprites/enemies/new-to-replace-old/parrot.png"),
	"penguin": preload("res://assets/sprites/enemies/new-to-replace-old/penguin.png"),
	"pig": preload("res://assets/sprites/enemies/new-to-replace-old/pig.png"),
	"rabbit": preload("res://assets/sprites/enemies/new-to-replace-old/rabbit.png"),
	"snake": preload("res://assets/sprites/enemies/new-to-replace-old/snake.png")
}

# Health by animal size (common sense)
const ANIMAL_HEALTH = {
	# Large animals - high HP
	"elephant": 100,
	"hippo": 90,
	"giraffe": 80,
	# Medium animals - medium HP
	"panda": 60,
	"pig": 55,
	"monkey": 50,
	# Small animals - low HP
	"rabbit": 35,
	"snake": 30,
	"parrot": 25,
	"penguin": 30
}

# Speed by animal size (inverse of health)
const ANIMAL_SPEEDS = {
	# Large animals - slow
	"elephant": 12,
	"hippo": 14,
	"giraffe": 16,
	# Medium animals - medium speed
	"panda": 18,
	"pig": 19,
	"monkey": 22,
	# Small animals - fast
	"rabbit": 26,
	"snake": 24,
	"parrot": 28,
	"penguin": 20
}

func _ready():
	add_to_group("enemies")
	z_index = -8  # In front of decor (decor is at -9)
	current_health = max_health


func find_world_map():
	if not is_inside_tree():
		return

	var world_maps = get_tree().get_nodes_in_group("world_map")
	if world_maps.size() > 0:
		world_map = world_maps[0]
	else:
		# Fallback: find by name in scene tree
		var world = get_tree().current_scene
		if world:
			world_map = world.get_node_or_null("WorldMap")

func _physics_process(_delta):
	if current_state == State.DYING:
		return

	match current_state:
		State.IDLE:
			handle_idle_state()
		State.WALK_TO_DECOR:
			handle_walk_to_decor_state()
		State.STANDING:
			handle_standing_state()
			
	# Apply knockback if any
	if knockback_velocity.length() > 5.0:
		velocity += knockback_velocity
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 500 * _delta)
		move_and_slide()
	elif knockback_velocity.length() > 0:
		knockback_velocity = Vector2.ZERO

func handle_idle_state():
	# Try to claim a decor position
	if not world_map:
		find_world_map()
		return

	var nearest_decor = world_map.get_nearest_available_decor(global_position)
	if nearest_decor != Vector2.INF:
		if world_map.claim_decor(nearest_decor):
			claimed_decor_pos = nearest_decor
			current_state = State.WALK_TO_DECOR

func handle_walk_to_decor_state():
	if claimed_decor_pos == Vector2.INF:
		current_state = State.IDLE
		return

	# Check if decor still exists (room might have unloaded)
	if world_map and not world_map.decor_positions.has(claimed_decor_pos):
		claimed_decor_pos = Vector2.INF
		current_state = State.IDLE
		return

	var distance_to_decor = global_position.distance_to(claimed_decor_pos)

	# Check if arrived at decor
	if distance_to_decor <= 5.0:
		global_position = claimed_decor_pos  # Snap to exact position
		velocity = Vector2.ZERO
		current_state = State.STANDING
		return

	# Move towards decor
	var direction = (claimed_decor_pos - global_position).normalized()
	velocity = direction * speed
	move_and_slide()

func handle_standing_state():
	# Just stand there, do nothing
	velocity = Vector2.ZERO

func take_damage(amount: int):
	current_health -= amount

	# Emit damage event
	EventBus.enemy_damaged.emit(self, amount)

	# Check for death
	if current_health <= 0:
		die()

func die():
	if current_state == State.DYING:
		return

	current_state = State.DYING

	# Stop processing
	set_process(false)
	set_physics_process(false)

	# Release claimed decor position
	if world_map and claimed_decor_pos != Vector2.INF:
		world_map.release_decor(claimed_decor_pos)
		claimed_decor_pos = Vector2.INF

	# Emit death event
	EventBus.enemy_died.emit(self, global_position)

	# Give XP to player
	EventBus.player_xp_gained.emit(xp_reward)

	# Return to pool
	Pools.return_enemy(self)

func get_health_percentage() -> float:
	if max_health <= 0:
		return 0.0
	return float(current_health) / float(max_health)

func is_alive() -> bool:
	return current_health > 0 and current_state != State.DYING

func apply_knockback(force: Vector2):
	knockback_velocity += force

func prepare_for_pool():
	velocity = Vector2.ZERO
	visible = false
	# Release decor if claimed
	if world_map and claimed_decor_pos != Vector2.INF:
		world_map.release_decor(claimed_decor_pos)
		claimed_decor_pos = Vector2.INF
	set_process(false)
	set_physics_process(false)
	set_deferred("process_mode", Node.PROCESS_MODE_DISABLED)

func prepare_for_spawn():
	current_state = State.IDLE
	claimed_decor_pos = Vector2.INF
	velocity = Vector2.ZERO
	visible = true
	z_index = -8  # Ensure z-index is set
	process_mode = Node.PROCESS_MODE_INHERIT
	set_process(true)
	set_physics_process(true)


func apply_enemy_type(type_name: String):
	enemy_type = type_name

	# Apply animal-specific stats
	if ANIMAL_HEALTH.has(enemy_type):
		max_health = ANIMAL_HEALTH[enemy_type]
		current_health = max_health

	if ANIMAL_SPEEDS.has(enemy_type):
		speed = ANIMAL_SPEEDS[enemy_type]

	# Set XP reward based on health tier
	if max_health >= 80:
		xp_reward = 75  # Large animals
	elif max_health >= 50:
		xp_reward = 50  # Medium animals
	else:
		xp_reward = 25  # Small animals

	# Swap sprite texture
	var sprite: Sprite2D = $Sprite2D
	if sprite and ANIMAL_SPRITES.has(enemy_type):
		sprite.texture = ANIMAL_SPRITES[enemy_type]

func reset():
	prepare_for_spawn()
	apply_enemy_type(enemy_type)
