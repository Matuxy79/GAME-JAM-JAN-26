## Player script. does game stuff in a simple way.
extends CharacterBody2D
class_name Player

# Player boss. Keeps health/xp, talks to parts, and yells to the game.

# Move and basic numbers
@export var speed: float = 200.0
@export var max_health: int = 100
@export var pickup_range: float = 80.0

# Level stuff
var current_health: int
var level: int = 1
var xp: int = 0
var xp_to_next_level: int

# Extra boost numbers
# Heal a bit when we hurt bad guys (0.1 = 10%)
var life_steal_ratio: float = 0.0
var xp_multiplier: float = 1.0
var speed_multiplier: float = 1.0
var powerup_charges: int = 0

# Power mode flags
var has_power_choice: bool = false
var pending_power_duration: float = 0.0
var power_mode_active: bool = false
var power_mode_timer: float = 0.0
var saved_basic_weapon_index: int = 0
var next_power_weapon: String = "laser_beam"

# My parts
var movement_component: MovementComponent
var health_component: HealthComponent
var pickup_magnet: PickupMagnet
var weapon_manager: WeaponManager

func _ready():
	print("Player initialized")
	setup_components()
	setup_signals()
	initialize_stats()

# Grab my parts and set numbers.
func setup_components():
	# Get component references from child nodes
	movement_component = $MovementComponent
	health_component = $HealthComponent
	pickup_magnet = $PickupMagnet
	weapon_manager = $WeaponManager
	
	# Configure components with player properties
	if movement_component:
		# Set how fast we move
		movement_component.speed = speed * speed_multiplier
	if health_component:
		# Set health
		health_component.max_health = max_health
		health_component.current_health = max_health
	if pickup_magnet:
		# Set how far we grab stuff
		pickup_magnet.pickup_range = pickup_range

# Wire signals so we hear about health/xp/power stuff.
func setup_signals():
	# Connect to EventBus signals for game events
	EventBus.player_health_changed.connect(_on_health_changed)
	EventBus.player_xp_gained.connect(_on_xp_gained)
	EventBus.player_level_up.connect(_on_level_up)
	EventBus.enemy_damaged.connect(_on_enemy_damaged)
	if not EventBus.powerup_collected.is_connected(_on_powerup_collected):
		EventBus.powerup_collected.connect(_on_powerup_collected)
	
	# Connect component-specific signals
	if health_component:
		health_component.health_changed.connect(_on_health_component_health_changed)
		health_component.died.connect(_on_health_component_died)

# Start health/xp and tell UI.
func initialize_stats():
	current_health = max_health
	xp_to_next_level = BalanceDB.get_xp_required_for_level(level + 1)
	powerup_charges = 0
	
	# Emit initial stats for UI and other systems
	EventBus.player_health_changed.emit(current_health, max_health)
	EventBus.hud_health_updated.emit(current_health, max_health)
	EventBus.hud_level_updated.emit(level)
	EventBus.powerup_charges_changed.emit(powerup_charges)

func _physics_process(delta):
	# Check for powerup button
	if Input.is_action_just_pressed("activate_powerup_choice") and powerup_charges > 0:
		var all_powerups = BalanceDB.powerup_data.keys()
		EventBus.show_powerup_choice_modal.emit(all_powerups)

	# Process player components
	if movement_component:
		# Move based on input
		movement_component.process_movement(delta)
	
	if weapon_manager:
		# Auto-fire
		weapon_manager.process_weapons(delta)
	
	# Update temporary power mode timer
	_update_power_mode(delta)
	
	# Tell others where we are
	EventBus.player_moved.emit(global_position)

# Another system said our health changed.
func _on_health_changed(new_health: int, _max_health: int):
	current_health = new_health
	self.max_health = max_health

# Our own health part pinged us.
func _on_health_component_health_changed(new_health: int, _max_health: int):
	current_health = new_health
	EventBus.player_health_changed.emit(current_health, max_health)
	EventBus.hud_health_updated.emit(current_health, max_health)

# Health hit zero, tell the game we died.
func _on_health_component_died():
	EventBus.player_died.emit()
	EventBus.game_over.emit(calculate_final_score())

# Got XP, maybe level up.
func _on_xp_gained(amount: int):
	xp += int(amount * xp_multiplier)
	EventBus.hud_xp_updated.emit(xp, xp_to_next_level)
	
	# Check if player has enough XP for level up
	if xp >= xp_to_next_level:
		level_up()

# Something else leveled us up, update counters.
func _on_level_up(new_level: int):
	level = new_level
	xp_to_next_level = BalanceDB.get_xp_required_for_level(level + 1)
	EventBus.hud_level_updated.emit(level)
	EventBus.level_up_available.emit(get_available_perks())

# Do level up math and show perks.
func level_up():
	level += 1
	xp -= xp_to_next_level
	xp_to_next_level = BalanceDB.get_xp_required_for_level(level + 1)
	
	# Emit level up events
	EventBus.player_level_up.emit(level)
	EventBus.hud_level_updated.emit(level)
	EventBus.hud_xp_updated.emit(xp, xp_to_next_level)
	
	# Show level up modal for perk selection
	var available_perks = get_available_perks()
	EventBus.show_level_up_modal.emit(available_perks)

# Pick 3 random perks to show.
func get_available_perks() -> Array:
	# Return 3 random perks for selection
	var all_perks = BalanceDB.perk_data.keys()
	var available_perks = []
	
	# Select 3 random perks without replacement
	for i in range(3):
		if all_perks.size() > 0:
			var random_perk = Rng.random_choice(all_perks)
			available_perks.append(random_perk)
			all_perks.erase(random_perk)
	
	return available_perks

# Use the perk we picked.
func apply_perk(perk_name: String):
	var perk_data = BalanceDB.get_perk_data(perk_name)
	if perk_data.is_empty():
		return
	
	# Apply perk effects based on type
	match perk_data.effect:
		"max_health":
			max_health += perk_data.value
			current_health += perk_data.value
			health_component.max_health = max_health
			health_component.current_health = current_health
			print("Perk applied: Health Boost → max_health now ", max_health)
		"damage_multiplier":
			if weapon_manager:
				weapon_manager.damage_multiplier *= perk_data.value
				print("Perk applied: Damage Boost → damage_multiplier now ", weapon_manager.damage_multiplier)
		"life_steal":
			# Increase life steal ratio (e.g., 0.1 = heal 10% of damage dealt)
			life_steal_ratio += float(perk_data.value)
			print("Perk applied: Life Steal → life_steal_ratio now ", life_steal_ratio)
		"pierce_bonus":
			if weapon_manager:
				weapon_manager.pierce_bonus += int(perk_data.value)
				print("Perk applied: Pierce Shot → pierce_bonus now ", weapon_manager.pierce_bonus)
		"explosive_radius":
			if weapon_manager:
				weapon_manager.explosive_radius_multiplier += float(perk_data.value)
				print("Perk applied: Explosive Rounds → radius_multiplier now ", weapon_manager.explosive_radius_multiplier)
		"xp_multiplier":
			xp_multiplier *= perk_data.value
			print("Perk applied: XP Boost → xp_multiplier now ", xp_multiplier)
		"speed_multiplier":
			speed_multiplier *= perk_data.value
			if movement_component:
				movement_component.speed = speed * speed_multiplier
			print("Perk applied: Speed Boost → speed_multiplier now ", speed_multiplier)
		"fire_rate_multiplier":
			if weapon_manager:
				weapon_manager.fire_rate_multiplier *= perk_data.value
				print("Perk applied: Fire Rate Boost → fire_rate_multiplier now ", weapon_manager.fire_rate_multiplier)
	
	# Save perk selection for progression tracking
	var selected_perks = Save.get_save_data("perks_selected", [])
	selected_perks.append(perk_name)
	Save.set_save_data("perks_selected", selected_perks)

# Quick score math for game over screen.
func calculate_final_score() -> int:
	# Simple score calculation based on level and time survived
	var game_time = Save.get_save_data("game_time", 0.0)
	return level * 1000 + int(game_time)

# Hurt us.
func take_damage(amount: int):
	if health_component:
		health_component.take_damage(amount)

# Heal us.
func heal(amount: int):
	if health_component and amount > 0:
		health_component.heal(amount)

# If we hit, heal a little.
func _on_enemy_damaged(_enemy: Node2D, damage: int):
	# Life steal: when we damage an enemy, heal for a percentage of damage dealt.
	if life_steal_ratio <= 0.0:
		return
	if damage <= 0:
		return
	
	var heal_amount := int(round(float(damage) * life_steal_ratio))
	if heal_amount > 0:
		print("Life steal: healing ", heal_amount, " from ", damage, " damage (ratio ", life_steal_ratio, ")")
		heal(heal_amount)

# Picked up a powerup, add a charge.
func _on_powerup_collected(duration: float):
	powerup_charges += 1
	EventBus.powerup_charges_changed.emit(powerup_charges)
	print("[Player._on_powerup_collected] PowerUp collected. Charges: ", powerup_charges)

# Count down power mode.
func _update_power_mode(delta: float):
	# Update power mode timer
	if power_mode_active:
		power_mode_timer -= delta
		if power_mode_timer <= 0.0:
			_end_power_mode()

# Turn on power weapon for a bit.
func activate_power_mode(powerup_name: String, duration: float):
	# Validate powerup charges
	if powerup_charges <= 0:
		return

	var powerup_data = BalanceDB.get_powerup_data(powerup_name)
	if powerup_data.is_empty():
		return

	# Public method called by PowerUpChoiceModal when player selects a weapon
	if not weapon_manager:
		print("[Player.activate_power_mode] ERROR: WeaponManager not found")
		return
	
	# Consume powerup charge
	powerup_charges -= 1
	EventBus.powerup_charges_changed.emit(powerup_charges)
	
	# Save current weapon to restore later
	saved_basic_weapon_index = weapon_manager.current_weapon_index
	
	# Find target power weapon index
	var weapon_name = powerup_data.get("weapon")
	var idx := weapon_manager.weapons.find(weapon_name)
	if idx == -1:
		print("[Player.activate_power_mode] ERROR: weapon ", weapon_name, " not found in WeaponManager.weapons")
		return
	
	# Activate power mode
	weapon_manager.current_weapon_index = idx
	weapon_manager.apply_powerup(powerup_data)
	power_mode_active = true
	power_mode_timer = max(duration, 0.1)
	has_power_choice = false
	EventBus.powerup_activated.emit(duration)
	print("[Player.activate_power_mode] Power mode started: ", weapon_name, " for ", power_mode_timer, " seconds. Charges left: ", powerup_charges)

# Turn off power mode and go back to normal weapon.
func _end_power_mode():
	if not power_mode_active:
		return
	power_mode_active = false
	if weapon_manager:
		weapon_manager.current_weapon_index = saved_basic_weapon_index
		weapon_manager.clear_powerup()
	print("[Player._end_power_mode] Power mode ended, reverting to weapon index ", saved_basic_weapon_index)

# Alive check.
func is_alive() -> bool:
	return current_health > 0
