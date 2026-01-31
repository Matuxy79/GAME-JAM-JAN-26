## Enemy script. does game stuff in a simple way.
extends CharacterBody2D
class_name Enemy

# Enemy - Individual enemy AI with seek, attack, and die behaviors
# Uses state machine for different behaviors

enum State {
	IDLE,
	SEEK_PLAYER,
	ATTACK,
	DYING
}

@export var enemy_type: String = "basic_enemy"
@export var max_health: int = 50
@export var speed: float = 100.0
@export var attack_damage: int = 10
@export var attack_range: float = 30.0
@export var detection_range: float = 150.0
@export var xp_reward: int = 25

var current_health: int
var current_state: State = State.IDLE
var player: Node2D
var attack_timer: float = 0.0
var attack_cooldown: float = 1.0

func _ready():
	add_to_group("enemies")
	current_health = max_health
	load_enemy_data()
	calculate_attack_range()
	calculate_detection_range()
	print("Enemy initialized: ", enemy_type, " - Attack range: ", attack_range, " - Detection range: ", detection_range)

func load_enemy_data():
	var enemy_data = BalanceDB.get_enemy_data(enemy_type)
	if not enemy_data.is_empty():
		max_health = int(enemy_data.get("health", max_health))
		speed = float(enemy_data.get("speed", speed))
		attack_damage = int(enemy_data.get("damage", attack_damage))
		xp_reward = int(enemy_data.get("xp_reward", xp_reward))
		# attack_range and detection_range will be calculated based on world scope, not from data
		attack_cooldown = float(enemy_data.get("attack_cooldown", attack_cooldown))
		current_health = max_health

func calculate_attack_range():
	# Fixed attack range for open world
	attack_range = 100.0

func calculate_detection_range():
	# Fixed detection range for open world
	detection_range = 500.0

func _physics_process(delta):
	# Don't process if dying/returned to pool
	if current_state == State.DYING:
		return
	
	match current_state:
		State.IDLE:
			handle_idle_state()
		State.SEEK_PLAYER:
			handle_seek_state(delta)
		State.ATTACK:
			handle_attack_state(delta)
		State.DYING:
			handle_dying_state()

func handle_idle_state():
	# Look for player
	if can_see_player():
		current_state = State.SEEK_PLAYER
		print("Enemy spotted player, switching to seek state")

func handle_seek_state(_delta):
	if not player or not is_instance_valid(player):
		find_player()
		return
	
	var distance_to_player = global_position.distance_to(player.global_position)
	
	# Check if player is in attack range
	if distance_to_player <= attack_range:
		current_state = State.ATTACK
		print("Player in attack range (", distance_to_player, " <= ", attack_range, "), switching to attack state")
		return
	
	# Check if player is still in detection range
	if distance_to_player > detection_range:
		current_state = State.IDLE
		print("Player out of range, switching to idle state")
		return
	
	# Move towards player
	var direction = (player.global_position - global_position).normalized()
	velocity = direction * speed
	move_and_slide()

func handle_attack_state(delta):
	if not player or not is_instance_valid(player):
		current_state = State.IDLE
		return
	
	var distance_to_player = global_position.distance_to(player.global_position)
	
	# Check if player is still in attack range
	if distance_to_player > attack_range:
		current_state = State.SEEK_PLAYER
		print("Player out of attack range (", distance_to_player, " > ", attack_range, "), switching to seek state")
		return
	
	# Attack if cooldown is ready
	if attack_timer <= 0:
		attack_player()
		attack_timer = attack_cooldown
	else:
		attack_timer -= delta

func handle_dying_state():
	# No-op when using pooling - Pools.return_enemy() handles cleanup
	# Don't queue_free() here as it conflicts with pooling
	# The die() method stops processing and returns to pool
	pass

func can_see_player() -> bool:
	find_player()
	if not player or not is_instance_valid(player):
		return false
	
	var distance = global_position.distance_to(player.global_position)
	return distance <= detection_range

func find_player():
	# Find player in scene
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

func attack_player():
	if not player or not is_instance_valid(player):
		return
	
	print("Enemy attacking player for ", attack_damage, " damage")
	
	# Deal damage to player
	if player.has_method("take_damage"):
		player.take_damage(attack_damage)
	
	# NOTE: We intentionally do NOT emit `enemy_damaged` here.
	# That signal represents damage dealt *to* enemies, not damage
	# dealt by enemies to the player. This keeps life-steal logic
	# simple on the player side.

func take_damage(amount: int):
	current_health -= amount
	print("Enemy took ", amount, " damage. Health: ", current_health, "/", max_health)
	
	# Emit damage event
	EventBus.enemy_damaged.emit(self, amount)
	
	# Check for death
	if current_health <= 0:
		die()

func die():
	# Prevent double-call
	if current_state == State.DYING:
		return
	
	print("Enemy died!")
	current_state = State.DYING
	
	# Stop processing immediately to prevent handle_dying_state() from running
	set_process(false)
	set_physics_process(false)
	
	# Emit death event
	EventBus.enemy_died.emit(self, global_position)
	
	# Give XP to player
	if player and is_instance_valid(player):
		EventBus.player_xp_gained.emit(xp_reward)
	
	# Return to pool (pool handles cleanup, no queue_free needed)
	Pools.return_enemy(self)

func get_health_percentage() -> float:
	if max_health <= 0:
		return 0.0
	return float(current_health) / float(max_health)

func is_alive() -> bool:
	return current_health > 0 and current_state != State.DYING

func prepare_for_pool():
	velocity = Vector2.ZERO
	visible = false
	set_process(false)
	set_physics_process(false)
	set_deferred("process_mode", Node.PROCESS_MODE_DISABLED)

func prepare_for_spawn():
	current_state = State.IDLE
	player = null
	attack_timer = 0.0
	velocity = Vector2.ZERO
	visible = true
	process_mode = Node.PROCESS_MODE_INHERIT
	set_process(true)
	set_physics_process(true)

func apply_enemy_type(type_name: String):
	enemy_type = type_name
	load_enemy_data()
	current_health = max_health
	calculate_attack_range()
	calculate_detection_range()
	
	# Swap sprite texture based on enemy type so variants share logic but look different.
	var sprite: Sprite2D = $Sprite2D
	if sprite:
		match enemy_type:
			"basic_enemy":
				sprite.texture = preload("res://assets/sprites/enemies/enemy.png")
			"fast_enemy":
				sprite.texture = preload("res://assets/sprites/enemies/enemyFast.png")
			"tank_enemy":
				sprite.texture = preload("res://assets/sprites/enemies/enemyBig.png")

func reset():
	# Legacy reset for compatibility with pooling
	prepare_for_spawn()
	apply_enemy_type(enemy_type)
