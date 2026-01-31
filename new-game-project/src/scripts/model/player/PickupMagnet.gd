## PickupMagnet script. does game stuff in a simple way.
extends Area2D
class_name PickupMagnet

# Magic magnet. Pulls shiny stuff in and grabs it when close.

@export var pickup_range: float = 80.0
@export var attraction_speed: float = 200.0
@export var collection_range: float = 20.0

var parent: Node2D

func _ready():
	parent = get_parent()

	# Configure Area2D
	var collision_shape = CollisionShape2D.new()
	var circle_shape = CircleShape2D.new()
	circle_shape.radius = pickup_range
	collision_shape.shape = circle_shape
	add_child(collision_shape)

	# Wire the area signals
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)

	print("PickupMagnet initialized with range: ", pickup_range)

func _process(delta):
	# Pull in shiny stuff
	var areas = get_overlapping_areas()
	for area in areas:
		if area.is_in_group("xp_gem"):
			attract_xp_gem(area, delta)
		elif area.is_in_group("powerup"):
			attract_powerup(area, delta)

func _on_area_entered(area: Area2D):
	if area.is_in_group("xp_gem"):
		print("XP gem entered pickup range")
	elif area.is_in_group("powerup"):
		print("PowerUp entered pickup range")

func _on_area_exited(area: Area2D):
	if area.is_in_group("xp_gem"):
		print("XP gem left pickup range")
	elif area.is_in_group("powerup"):
		print("PowerUp left pickup range")

func attract_xp_gem(xp_gem: Node2D, delta: float):
	if not xp_gem or not is_instance_valid(xp_gem):
		return
	
	var direction = (parent.global_position - xp_gem.global_position).normalized()
	var distance = parent.global_position.distance_to(xp_gem.global_position)
	
	# Move gem towards player
	if distance > collection_range:
		var move_distance = attraction_speed * delta
		xp_gem.global_position += direction * move_distance
	else:
		# Collect the gem
		collect_xp_gem(xp_gem)

func collect_xp_gem(xp_gem: Node2D):
	if not xp_gem or not is_instance_valid(xp_gem):
		return
	
	# Check if already collected (prevent double collection)
	if xp_gem.has_method("is_collected") and xp_gem.is_collected():
		return
	
	# Call gem's collect method (it will emit events and handle pooling)
	# DO NOT emit events here - let the gem handle it
	if xp_gem.has_method("collect"):
		xp_gem.collect()
	else:
		# Fallback if gem doesn't have collect method
		var xp_amount = xp_gem.get_xp_amount() if xp_gem.has_method("get_xp_amount") else 10
		EventBus.xp_gem_collected.emit(xp_amount)
		EventBus.player_xp_gained.emit(xp_amount)
		xp_gem.queue_free()
	
	print("Collected XP gem")

func attract_powerup(powerup: Node2D, delta: float):
	if not powerup or not is_instance_valid(powerup):
		print("[PickupMagnet.attract_powerup] PowerUp invalid or null")
		return
	
	var direction = (parent.global_position - powerup.global_position).normalized()
	var distance = parent.global_position.distance_to(powerup.global_position)
	
	# Move powerup towards player
	if distance > collection_range:
		var move_distance = attraction_speed * delta
		powerup.global_position += direction * move_distance
		# Uncomment for spam: print("[PickupMagnet.attract_powerup] Moving powerup, distance: ", distance)
	else:
		# Collect the powerup
		print("[PickupMagnet.attract_powerup] PowerUp in collection range! Distance: ", distance)
		collect_powerup(powerup)

func collect_powerup(powerup: Node2D):
	if not powerup or not is_instance_valid(powerup):
		print("[PickupMagnet.collect_powerup] PowerUp invalid or null")
		return
	
	# Check if already collected (prevent double collection)
	if powerup.has_method("is_collected_state") and powerup.is_collected_state():
		print("[PickupMagnet.collect_powerup] PowerUp already collected, skipping")
		return
	
	print("[PickupMagnet.collect_powerup] Calling powerup.collect()")
	# Call powerup's collect method (it will emit events and handle pooling)
	if powerup.has_method("collect"):
		powerup.collect()
	else:
		print("[PickupMagnet.collect_powerup] ERROR: PowerUp doesn't have collect() method!")
	
	print("[PickupMagnet.collect_powerup] Collected PowerUp")

func set_pickup_range(new_range: float):
	pickup_range = new_range
	
	# Update collision shape
	var collision_shape = get_child(0) as CollisionShape2D
	if collision_shape and collision_shape.shape is CircleShape2D:
		(collision_shape.shape as CircleShape2D).radius = pickup_range

func get_pickup_range() -> float:
	return pickup_range
