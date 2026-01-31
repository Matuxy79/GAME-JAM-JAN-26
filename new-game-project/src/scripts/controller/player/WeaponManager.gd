## WeaponManager script. does game stuff in a simple way.
extends Node
class_name WeaponManager

# Weapon brains. Keeps a list, decides when to shoot, and spawns projectiles.

@export var weapons: Array[String] = ["basic_laser", "laser_beam", "spike_ring", "laserspikeball"]
@export var current_weapon_index: int = 0
@export var damage_multiplier: float = 1.0

var fire_timers: Dictionary = {}
var pierce_bonus: int = 0 # Extra pierce from perks (e.g., Pierce Shot)
var explosive_radius_multiplier: float = 1.0 # Size multiplier for projectiles from Explosive Rounds perk
var fire_rate_multiplier: float = 1.0

var temp_fire_rate_multiplier: float = 1.0
var temp_damage_multiplier: float = 1.0
var temp_projectile_speed_multiplier: float = 1.0
var powerup_timer: float = 0.0

var parent: Node2D

func _ready():
	parent = get_parent()
	setup_weapons()
	print("WeaponManager initialized with weapons: ", weapons)

func setup_weapons():
	# Initialize fire timers for each weapon
	for weapon_name in weapons:
		fire_timers[weapon_name] = 0.0

func process_weapons(delta: float):
	if not parent:
		return

	if powerup_timer > 0:
		powerup_timer -= delta
		if powerup_timer <= 0:
			clear_powerup()
	
	# Update fire timers
	for weapon_name in fire_timers.keys():
		if fire_timers[weapon_name] > 0:
			fire_timers[weapon_name] -= delta
	
	# Auto-fire current weapon
	fire_current_weapon()

func fire_current_weapon():
	if weapons.is_empty():
		return
	
	var current_weapon = weapons[current_weapon_index]
	var weapon_data = BalanceDB.get_weapon_data(current_weapon)
	
	if weapon_data.is_empty():
		return
	
	# Check if weapon can fire
	if fire_timers[current_weapon] <= 0:
		fire_weapon(current_weapon, weapon_data)

func fire_weapon(weapon_name: String, weapon_data: Dictionary):
	# Get fire rate from weapon data
	var fire_rate = weapon_data.get("fire_rate", 1.0) * fire_rate_multiplier * temp_fire_rate_multiplier
	fire_timers[weapon_name] = 1.0 / fire_rate
	
	# Get firing direction (towards nearest enemy or mouse)
	var direction = get_firing_direction()
	
	# Create projectile
	spawn_projectile(weapon_name, weapon_data, direction)
	
	# Emit weapon fired event
	EventBus.weapon_fired.emit(weapon_name, direction)

func get_firing_direction() -> Vector2:
	# Try to find nearest enemy
	var enemies = get_tree().get_nodes_in_group("enemies")
	var nearest_enemy = null
	var nearest_distance = INF
	
	for enemy in enemies:
		if enemy and is_instance_valid(enemy):
			var distance = parent.global_position.distance_to(enemy.global_position)
			if distance < nearest_distance:
				nearest_distance = distance
				nearest_enemy = enemy
	
	if nearest_enemy:
		return (nearest_enemy.global_position - parent.global_position).normalized()
	else:
		# Default to right direction
		return Vector2.RIGHT

func spawn_projectile(_weapon_name: String, weapon_data: Dictionary, direction: Vector2):
	# Get projectile from pool
	var projectile = Pools.get_projectile()
	if not projectile:
		return
	
	# Position projectile at player
	projectile.global_position = parent.global_position
	
	# Configure projectile
	var damage = weapon_data.get("damage", 10) * damage_multiplier * temp_damage_multiplier
	var speed = weapon_data.get("projectile_speed", 300) * temp_projectile_speed_multiplier
	# Make range full-screen: use viewport diagonal so projectiles reach corners
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var range_distance = viewport_size.length()
	
	projectile.setup(damage, speed, direction, range_distance, explosive_radius_multiplier)
	
	# Set projectile sprite from weapon data
	var sprite_path: String = weapon_data.get("sprite", "res://assets/sprites/weapons/laser.png")
	var sprite_node: Sprite2D = projectile.get_node_or_null("Sprite2D")
	if sprite_node:
		var tex := load(sprite_path)
		if tex:
			sprite_node.texture = tex
			print("WeaponManager: using sprite", sprite_path)
	
	# Apply pierce based on weapon data + any perk bonus
	var base_pierce: int = int(weapon_data.get("pierce", 0))
	projectile.pierce_count = base_pierce + pierce_bonus
	print("Projectile spawned → damage=", damage, " base_pierce=", base_pierce, " bonus_pierce=", pierce_bonus, " total_pierce=", projectile.pierce_count)
	
	# Add to scene
	get_tree().current_scene.add_child(projectile)
	
	# Emit projectile fired event
	EventBus.projectile_fired.emit(projectile, direction)

func apply_powerup(powerup_data: Dictionary):
	clear_powerup() # Clear any existing powerup
	powerup_timer = powerup_data.get("duration", 30.0)

	if "effect" in powerup_data:
		var effect = powerup_data["effect"]
		var value = powerup_data["value"]
		match effect:
			"fire_rate_multiplier":
				temp_fire_rate_multiplier = value
			"damage_multiplier":
				temp_damage_multiplier = value
			"projectile_speed_multiplier":
				temp_projectile_speed_multiplier = value
	elif "effects" in powerup_data:
		for effect_data in powerup_data["effects"]:
			var effect = effect_data["effect"]
			var value = effect_data["value"]
			match effect:
				"fire_rate_multiplier":
					temp_fire_rate_multiplier = value
				"damage_multiplier":
					temp_damage_multiplier = value
				"projectile_speed_multiplier":
					temp_projectile_speed_multiplier = value

func clear_powerup():
	temp_fire_rate_multiplier = 1.0
	temp_damage_multiplier = 1.0
	temp_projectile_speed_multiplier = 1.0
	powerup_timer = 0.0


func add_weapon(weapon_name: String):
	if weapon_name not in weapons:
		weapons.append(weapon_name)
		fire_timers[weapon_name] = 0.0
		print("Added weapon: ", weapon_name)

func remove_weapon(weapon_name: String):
	if weapon_name in weapons:
		weapons.erase(weapon_name)
		fire_timers.erase(weapon_name)
		print("Removed weapon: ", weapon_name)

func switch_weapon(index: int):
	if index >= 0 and index < weapons.size():
		current_weapon_index = index
		print("Switched to weapon: ", weapons[current_weapon_index])

func get_current_weapon() -> String:
	if weapons.is_empty():
		return ""
	return weapons[current_weapon_index]

func get_weapon_count() -> int:
	return weapons.size()
