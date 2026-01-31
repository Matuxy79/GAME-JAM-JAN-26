## PowerUp script. does game stuff in a simple way.
extends Area2D
class_name PowerUp

# PowerUp pickup. Player grabs it and gets a special weapon for a bit.

@export var duration: float = 30.0
@export var collection_range: float = 20.0  # Match XP gem collection range
var is_collected: bool = false

func _ready():
	# Add this powerup to the "powerup" group so PickupMagnet can detect it
	add_to_group("powerup")
	
	print("[PowerUp._ready] Initializing PowerUp at ", global_position)
	
	# Make a circle so we can detect pickup
	var collision_shape = CollisionShape2D.new()
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = collection_range
	collision_shape.shape = circle_shape
	call_deferred("add_child", collision_shape)
	
	print("[PowerUp._ready] Collision shape created with radius: ", collection_range)
	
	# Set layers so player/magnet can see us
	collision_layer = 1 << 2      # e.g. loot layer
	collision_mask = 1 << 0       # detect player layer if needed, or use groups
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)
		print("[PowerUp._ready] area_entered signal connected")

func _on_area_entered(area: Area2D):
	# Magnet or player touching grabs it
	print("[PowerUp._on_area_entered] Area detected: ", area.name, " | Groups: ", area.get_groups())
	if area.is_in_group("player") or (area.name == "PickupMagnet"):
		print("[PowerUp._on_area_entered] Triggering collect!")
		collect()

func collect():
	if is_collected:
		print("[PowerUp.collect] Already collected, skipping")
		return
	
	is_collected = true
	print("[PowerUp.collect] PowerUp COLLECTED! Emitting signal with duration: ", duration)
	# Tell the game we got grabbed
	EventBus.powerup_collected.emit(duration)
	print("[PowerUp.collect] Signal emitted, returning to pool...")
	# Return to pool instead of queue_free
	Pools.return_powerup(self)
	print("[PowerUp.collect] Returned to pool")

func is_collected_state() -> bool:
	return is_collected

func reset():
	print("[PowerUp.reset] Resetting powerup - was_collected: ", is_collected, " | visibility: ", visible)
	is_collected = false
	visible = true  # Reset visibility when returned to pool
	print("[PowerUp.reset] Reset complete - is_collected: ", is_collected, " | visibility: ", visible)
