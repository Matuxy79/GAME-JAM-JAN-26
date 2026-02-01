## WeaponManager script. does game stuff in a simple way.
extends Node
class_name WeaponManager

# Weapon brains. Keeps a list, decides when to shoot, and spawns projectiles.

@export var weapons: Array[String] = ["pistol", "revolver", "smg", "assault_rifle", "shotgun"]
@export var current_weapon_index: int = 0
@export var damage_multiplier: float = 1.0

var fire_timers: Dictionary = {}
var pierce_bonus: int = 0 
var explosive_radius_multiplier: float = 1.0 
var fire_rate_multiplier: float = 1.0

var temp_fire_rate_multiplier: float = 1.0
var temp_damage_multiplier: float = 1.0
var temp_projectile_speed_multiplier: float = 1.0
var powerup_timer: float = 0.0

var parent: Node2D
var aim_pivot: Node2D
var weapon_socket: Sprite2D
var muzzle: Marker2D

var current_weapon_data: Dictionary = {}
var burst_shots_left: int = 0
var burst_timer: float = 0.0
var burst_interval: float = 0.1

func _ready():
	parent = get_parent()
	aim_pivot = parent.get_node_or_null("AimPivot")
	if aim_pivot:
		weapon_socket = aim_pivot.get_node_or_null("WeaponSocket")
		if weapon_socket:
			muzzle = weapon_socket.get_node_or_null("Muzzle")
	
	setup_input()
	setup_weapons()
	
	# Load initial weapon data
	if not weapons.is_empty():
		update_weapon_data(weapons[current_weapon_index])

func setup_input():
	if not InputMap.has_action("fire"):
		InputMap.add_action("fire")
		# Add Left Mouse Button
		var ev = InputEventMouseButton.new()
		ev.button_index = MOUSE_BUTTON_LEFT
		ev.pressed = true
		InputMap.action_add_event("fire", ev)

func setup_weapons():
	# Initialize fire timers
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
	
	# Update burst timer
	if burst_shots_left > 0:
		burst_timer -= delta
		if burst_timer <= 0:
			fire_burst_shot()
	
	# Aiming logic
	if aim_pivot:
		var mouse_pos = parent.get_global_mouse_position()
		aim_pivot.look_at(mouse_pos)
		
		# Flip weapon if aiming left
		var angle = aim_pivot.rotation_degrees
		# Normalize angle to -180 to 180
		while angle > 180: angle -= 360
		while angle < -180: angle += 360
		
		if weapon_socket:
			if abs(angle) > 90:
				weapon_socket.flip_v = true
			else:
				weapon_socket.flip_v = false

	# Input handling
	handle_input()

func handle_input():
	if weapons.is_empty(): return
	var weapon_name = weapons[current_weapon_index]
	
	# If burst is active, don't interrupt (or maybe do? mostly don't)
	if burst_shots_left > 0: return

	var can_fire = fire_timers[weapon_name] <= 0
	var fire_mode = current_weapon_data.get("fire_mode", "semi")
	
	if fire_mode == "auto":
		if Input.is_action_pressed("fire") and can_fire:
			fire_weapon_logic(weapon_name)
	
	elif fire_mode == "semi":
		if Input.is_action_just_pressed("fire") and can_fire:
			fire_weapon_logic(weapon_name)
			
	elif fire_mode == "burst":
		if Input.is_action_just_pressed("fire") and can_fire:
			start_burst(weapon_name)
			
	elif fire_mode == "charge":
		# Simple implementation: behave like semi for now, or hold check
		# For responsiveness, treating as semi with long cooldown
		if Input.is_action_just_pressed("fire") and can_fire:
			fire_weapon_logic(weapon_name)

func start_burst(weapon_name: String):
	var count = current_weapon_data.get("burst_count", 3)
	var interval = current_weapon_data.get("burst_interval", 0.06)
	
	burst_shots_left = count
	burst_interval = interval
	burst_timer = 0.0 # Start immediately
	
	# Set cooldown for the weapon immediately so you can't spam bursts
	# Burst cooldown usually = burst time + extra delay
	var fire_rate = get_modified_fire_rate()
	fire_timers[weapon_name] = (1.0 / fire_rate) + (count * interval)

func fire_burst_shot():
	var weapon_name = weapons[current_weapon_index]
	fire_single_shot(weapon_name, current_weapon_data)
	
	burst_shots_left -= 1
	burst_timer = burst_interval

func fire_weapon_logic(weapon_name: String):
	var fire_rate = get_modified_fire_rate()
	
	# Set cooldown
	fire_timers[weapon_name] = 1.0 / fire_rate
	
	# Fire
	fire_single_shot(weapon_name, current_weapon_data)

func fire_single_shot(weapon_name: String, weapon_data: Dictionary):
	# Calculate direction with spread
	var base_direction = Vector2.RIGHT
	if aim_pivot:
		base_direction = Vector2.RIGHT.rotated(aim_pivot.rotation)
	else:
		base_direction = get_firing_direction_legacy()
		
	var spread_deg = weapon_data.get("spread", 0.0)
	var pellets = weapon_data.get("pellets", 1)
	
	for i in range(pellets):
		var spread_angle = deg_to_rad(randf_range(-spread_deg/2.0, spread_deg/2.0))
		var final_direction = base_direction.rotated(spread_angle)
		spawn_projectile(weapon_name, weapon_data, final_direction)
	
	# Emit event
	EventBus.weapon_fired.emit(weapon_name, base_direction)

func spawn_projectile(_weapon_name: String, weapon_data: Dictionary, direction: Vector2):
	var projectile = Pools.get_projectile()
	if not projectile:
		return
	
	# Position
	var spawn_pos = parent.global_position
	if muzzle:
		spawn_pos = muzzle.global_position
	
	# Stats
	var damage = weapon_data.get("damage", 10) * damage_multiplier * temp_damage_multiplier
	var speed = weapon_data.get("projectile_speed", 300) * temp_projectile_speed_multiplier
	var range_dist = weapon_data.get("range", 700)
	var explosive_radius = weapon_data.get("explosive_radius", 0.0) * explosive_radius_multiplier
	var knockback = weapon_data.get("knockback", 0.0)
	
	# Setup
	projectile.setup(damage, speed, direction, range_dist, explosive_radius, knockback)
	
	# Pierce
	var base_pierce = int(weapon_data.get("pierce", 0))
	projectile.pierce_count = base_pierce + pierce_bonus
	
	# Sprite (optional override if projectile needs specific look)
	# Usually we might want a bullet sprite, but for now we use the default or one from data
	# If weapon data has "projectile_sprite", use it. Otherwise use default.
	# The weapon sprite in data is the GUN sprite, not bullet.
	# We'll stick to default projectile sprite for now unless specified.
	
	get_tree().current_scene.add_child(projectile)
	EventBus.projectile_fired.emit(projectile, direction)

func get_modified_fire_rate() -> float:
	var base_rate = current_weapon_data.get("fire_rate", 1.0)
	return base_rate * fire_rate_multiplier * temp_fire_rate_multiplier

func update_weapon_data(weapon_name: String):
	current_weapon_data = BalanceDB.get_weapon_data(weapon_name)
	
	# Update visual
	if weapon_socket:
		var sprite_path = current_weapon_data.get("sprite_path", "")
		if sprite_path != "":
			var tex = load(sprite_path)
			if tex:
				weapon_socket.texture = tex
		else:
			# Fallback or clear
			pass

func switch_weapon(index: int):
	if index >= 0 and index < weapons.size():
		current_weapon_index = index
		update_weapon_data(weapons[current_weapon_index])
		print("Switched to weapon: ", weapons[current_weapon_index])

func get_firing_direction_legacy() -> Vector2:
	# Fallback if no AimPivot
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
	return Vector2.RIGHT

func apply_powerup(powerup_data: Dictionary):
	clear_powerup()
	powerup_timer = powerup_data.get("duration", 30.0)
	# ... (keep existing powerup logic) ...
	if "effect" in powerup_data:
		var effect = powerup_data["effect"]
		var value = powerup_data["value"]
		match effect:
			"fire_rate_multiplier": temp_fire_rate_multiplier = value
			"damage_multiplier": temp_damage_multiplier = value
			"projectile_speed_multiplier": temp_projectile_speed_multiplier = value

func clear_powerup():
	temp_fire_rate_multiplier = 1.0
	temp_damage_multiplier = 1.0
	temp_projectile_speed_multiplier = 1.0
	powerup_timer = 0.0

func add_weapon(weapon_name: String):
	if weapon_name not in weapons:
		weapons.append(weapon_name)
		fire_timers[weapon_name] = 0.0

func remove_weapon(weapon_name: String):
	if weapon_name in weapons:
		weapons.erase(weapon_name)
		fire_timers.erase(weapon_name)