## XPGem script. does game stuff in a simple way.
extends Area2D
class_name XPGem

# XPGem - Collectible XP item
# Attracted by player's PickupMagnet and collected for XP

@export var xp_amount: int = 10
@export var collection_range: float = 10.0
@export var attraction_speed: float = 100.0

var _is_collected: bool = false
var player: Node2D

func _ready():
	add_to_group("xp_gem")
	
	# Setup Area2D for collection - defer to avoid physics flush conflict
	var collision_shape = CollisionShape2D.new()
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = collection_range
	collision_shape.shape = circle_shape
	call_deferred("add_child", collision_shape)
	
	# Connect signals
	body_entered.connect(_on_body_entered)
	
	print("XP Gem created with value: ", xp_amount)

func _process(_delta):
	if _is_collected:
		return
	
	# Find player for attraction
	if not player or not is_instance_valid(player):
		find_player()
		return
	
	# Check if player is close enough to collect
	var distance = global_position.distance_to(player.global_position)
	if distance <= collection_range:
		collect()

func find_player():
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

func _on_body_entered(body: Node2D):
	if body.is_in_group("player") and not _is_collected:
		collect()

func is_collected() -> bool:
	return _is_collected

func collect():
	if _is_collected:  # Guard against double collection
		return
	
	_is_collected = true
	
	# Emit collection events (ONLY ONCE)
	EventBus.xp_gem_collected.emit(xp_amount)
	EventBus.player_xp_gained.emit(xp_amount)
	
	print("XP Gem collected for ", xp_amount, " XP")
	
	# Return to pool
	Pools.return_xp_gem(self)

func set_xp_amount(amount: int):
	xp_amount = amount

func get_xp_amount() -> int:
	return xp_amount

func reset():
	# Reset gem for reuse
	_is_collected = false
	player = null
	visible = true
	process_mode = Node.PROCESS_MODE_INHERIT
