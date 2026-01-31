## LootManager script. does game stuff in a simple way.
extends Node
class_name LootManager

# LootManager - Handles loot drops and collection
# Manages XP gems, weapon drops, power-ups, and other collectibles

@export var xp_gem_base_value: int = 10
@export var xp_gem_variance: float = 0.5
@export var weapon_drop_chance: float = 0.1

var active_loot: Array[Node2D] = []

func _ready():
	print("LootManager initialized")
	setup_signals()

func setup():
	print("LootManager setup")
	setup_signals()

func setup_signals():
	# Connect to EventBus signals
	if not EventBus.enemy_died.is_connected(_on_enemy_died):
		EventBus.enemy_died.connect(_on_enemy_died)
	if not EventBus.xp_gem_collected.is_connected(_on_xp_gem_collected):
		EventBus.xp_gem_collected.connect(_on_xp_gem_collected)

func _on_enemy_died(enemy: Enemy, position: Vector2):
	# Always drop XP gem
	drop_xp_gem(position)
	
	# Chance to drop weapon (existing behaviour)
	if Rng.randf() < weapon_drop_chance:
		drop_weapon(position)
	
	# Chance to drop a temporary power-up
	var powerup_chance := 0.25
	if enemy.enemy_type == "fast_enemy" or enemy.enemy_type == "tank_enemy":
		powerup_chance = 0.5
	if Rng.randf() < powerup_chance:
		drop_powerup(position)

func drop_xp_gem(position: Vector2):
	var xp_gem = Pools.get_xp_gem()
	if not xp_gem:
		return
	
	# Calculate XP value with variance
	var xp_value = calculate_xp_value()
	xp_gem.set_xp_amount(xp_value)
	
	# Position the gem
	xp_gem.global_position = position
	
	# Add to scene
	get_tree().current_scene.call_deferred("add_child", xp_gem)
	active_loot.append(xp_gem)
	
	# Emit loot dropped event
	EventBus.loot_dropped.emit("xp_gem", position)
	
	print("Dropped XP gem with value: ", xp_value)

func drop_powerup(position: Vector2):
	var powerup = Pools.get_powerup()
	if not powerup:
		return
	
	powerup.global_position = position
	get_tree().current_scene.call_deferred("add_child", powerup)
	active_loot.append(powerup)
	EventBus.loot_dropped.emit("powerup", position)
	print("Dropped PowerUp at ", position)

func drop_weapon(position: Vector2):
	# For now, just log weapon drop
	# In a full implementation, this would spawn a weapon pickup
	print("Weapon dropped at ", position)
	EventBus.loot_dropped.emit("weapon", position)

func calculate_xp_value() -> int:
	var base_value = xp_gem_base_value
	var variance = Rng.randf_range(-xp_gem_variance, xp_gem_variance)
	var multiplier = 1.0 + variance
	return int(base_value * multiplier)

func _on_xp_gem_collected(amount: int):
	print("XP gem collected for ", amount, " XP")

func cleanup_loot():
	# Return all active loot to pools
	for loot in active_loot:
		if loot and is_instance_valid(loot):
			if loot.is_in_group("xp_gem"):
				Pools.return_xp_gem(loot)
			elif loot.is_in_group("powerup"):
				Pools.return_powerup(loot)
			else:
				loot.queue_free()
	
	active_loot.clear()
	print("Cleaned up all loot")

func get_active_loot_count() -> int:
	return active_loot.size()

func remove_loot_from_active(loot: Node2D):
	if loot in active_loot:
		active_loot.erase(loot)
