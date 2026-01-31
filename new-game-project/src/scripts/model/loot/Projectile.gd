## Projectile script. does game stuff in a simple way.
extends Area2D
class_name Projectile

# Projectile - Individual projectile with damage and movement
# Handles collision detection and damage dealing

@export var damage: int = 10
@export var speed: float = 300.0
@export var max_range: float = 200.0
@export var pierce_count: int = 0
@export var base_radius: float = 4.0

var direction: Vector2 = Vector2.RIGHT
var distance_traveled: float = 0.0
var current_pierce: int = 0
var radius_multiplier: float = 1.0

func _ready():
	# Use the CollisionShape2D defined in the scene and ensure collisions are enabled.
	var collision_shape: CollisionShape2D = $CollisionShape2D
	if collision_shape == null:
		push_error("Projectile is missing CollisionShape2D child")
	
	# Standardize collision layers/masks so projectiles always see enemies.
	# Layer 1: enemies, Layer 2: projectiles (convention for this project).
	collision_layer = 1 << 1      # projectiles live on layer 2
	collision_mask = 1 << 0       # they detect layer 1 (enemies)
	
	# Connect signals once.
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	
	print("Projectile ready with damage: ", damage, " layers=", collision_layer, " mask=", collision_mask)

func _physics_process(delta):
	# Move projectile
	var movement = direction * speed * delta
	global_position += movement
	distance_traveled += movement.length()
	
	# Check if projectile has traveled max range
	if distance_traveled >= max_range:
		destroy()

func setup(projectile_damage: int, projectile_speed: float, projectile_direction: Vector2, projectile_range: float, radius_mult: float = 1.0):
	damage = projectile_damage
	speed = projectile_speed
	direction = projectile_direction.normalized()
	max_range = projectile_range
	distance_traveled = 0.0
	current_pierce = 0
	radius_multiplier = radius_mult
	_update_hitbox_size()

func _update_hitbox_size():
	# Scale collision shape radius
	var collision_shape: CollisionShape2D = $CollisionShape2D
	if collision_shape and collision_shape.shape is CircleShape2D:
		var circle := collision_shape.shape as CircleShape2D
		circle.radius = base_radius * radius_multiplier
	
	# Scale sprite
	var sprite: Sprite2D = $Sprite2D
	if sprite:
		sprite.scale = Vector2.ONE * radius_multiplier

func _on_body_entered(body: Node2D):
	# Don't hit the player who fired it
	if body.is_in_group("player"):
		return
	
	# Hit enemy
	if body.is_in_group("enemies"):
		hit_enemy(body)
		return
	
	# Hit other projectiles (ignore)
	if body.is_in_group("projectiles"):
		return
	
	# Hit anything else
	hit_obstacle(body)

func hit_enemy(enemy: Node2D):
	var final_damage = damage
	# Apply global difficulty multiplier if available
	if Engine.has_singleton("BalanceDB"):
		var balance = Engine.get_singleton("BalanceDB")
		if balance.has_method("get_damage_multiplier"):
			final_damage = int(round(float(damage) * balance.get_damage_multiplier()))

	print("Projectile hit enemy for ", final_damage, " damage (base=", damage, ")")
	
	# Deal damage to enemy
	if enemy.has_method("take_damage"):
		enemy.take_damage(final_damage)
	
	# Emit hit event
	EventBus.projectile_hit.emit(enemy, final_damage)
	
	# Check pierce
	if current_pierce < pierce_count:
		current_pierce += 1
		print("Projectile pierced through enemy")
	else:
		destroy()


func hit_obstacle(_obstacle: Node2D):
	print("Projectile hit obstacle")
	destroy()

func destroy():
	print("Projectile destroyed")
	
	# Return to pool
	Pools.return_projectile(self)

func get_damage() -> int:
	return damage

func get_direction() -> Vector2:
	return direction
