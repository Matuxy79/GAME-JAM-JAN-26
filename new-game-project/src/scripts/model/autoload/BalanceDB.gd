## BalanceDB script. does game stuff in a simple way.
extends Node

# Balance stash. Loads JSON for weapons/enemies/powerups/perks/xp so code stays clean.

var xp_curve: Array[int] = []
var weapon_data: Dictionary = {}
var enemy_data: Dictionary = {}
var perk_data: Dictionary = {}
var powerup_data: Dictionary = {}

func _ready():
	print("BalanceDB initialized")
	load_balance_data()

# Load everything from JSON
func load_balance_data():
	load_xp_curve()
	load_weapon_data()
	load_enemy_data()
	load_perk_data()
	load_powerup_data()

# XP curve from file
func load_xp_curve():
	var file = FileAccess.open("res://src/resources/data/xp_curve.json", FileAccess.READ)
	if file == null:
		push_error("Failed to load xp_curve.json")
		create_default_xp_curve()
		return
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		push_error("Failed to parse xp_curve.json")
		create_default_xp_curve()
		return
	
	# Convert generic Array to Array[int]
	var raw_array = json.data.xp_curve as Array
	xp_curve = []
	for i in range(raw_array.size()):
		xp_curve.append(int(raw_array[i]))
	print("XP curve loaded: ", xp_curve.size(), " levels")

# Weapons from file
func load_weapon_data():
	var file = FileAccess.open("res://src/resources/data/weapons.json", FileAccess.READ)
	if file == null:
		print("No weapons.json found, using defaults")
		create_default_weapon_data()
		return
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		push_error("Failed to parse weapons.json")
		create_default_weapon_data()
		return
	
	weapon_data = json.data.weapons as Dictionary
	print("Weapon data loaded: ", weapon_data.size(), " weapons")

# Enemies from file
func load_enemy_data():
	var file = FileAccess.open("res://src/resources/data/enemies.json", FileAccess.READ)
	if file == null:
		print("No enemies.json found, using defaults")
		create_default_enemy_data()
		return
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		push_error("Failed to parse enemies.json")
		create_default_enemy_data()
		return
	
	enemy_data = json.data.enemies as Dictionary
	print("Enemy data loaded: ", enemy_data.size(), " enemy types")

# Perks from file
func load_perk_data():
	var file = FileAccess.open("res://src/resources/data/perks.json", FileAccess.READ)
	if file == null:
		print("No perks.json found, using defaults")
		create_default_perk_data()
		return
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		push_error("Failed to parse perks.json")
		create_default_perk_data()
		return
	
	perk_data = json.data.perks as Dictionary
	print("Perk data loaded: ", perk_data.size(), " perks")

# Powerups from file
func load_powerup_data():
	var file = FileAccess.open("res://src/resources/data/powerups.json", FileAccess.READ)
	if file == null:
		push_error("Failed to load powerups.json")
		return
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		push_error("Failed to parse powerups.json")
		return
	
	powerup_data = json.data.powerups as Dictionary
	print("Power-up data loaded: ", powerup_data.size(), " power-ups")

# XP needed for a level (0 if bad level)
func get_xp_required_for_level(level: int) -> int:
	if level <= 0 or level > xp_curve.size():
		return 0
	return xp_curve[level - 1]

# Grab weapon data
func get_weapon_data(weapon_name: String) -> Dictionary:
	return weapon_data.get(weapon_name, {})

# Grab enemy data
func get_enemy_data(enemy_type: String) -> Dictionary:
	return enemy_data.get(enemy_type, {})

# Grab perk data
func get_perk_data(perk_name: String) -> Dictionary:
	return perk_data.get(perk_name, {})

# Grab powerup data
func get_powerup_data(powerup_name: String) -> Dictionary:
	return powerup_data.get(powerup_name, {})

# Fallback XP curve
func create_default_xp_curve():
	xp_curve = [100, 200, 350, 550, 800, 1100, 1450, 1850, 2300, 2800]

# Fallback weapon data
func create_default_weapon_data():
	weapon_data = {
		"basic_laser": {
			"damage": 10,
			"fire_rate": 1.0,
			"range": 200,
			"projectile_speed": 300,
			"pierce": 0,
			"sprite": "res://assets/sprites/weapons/laser.png"
		}
	}

# Fallback enemy data
func create_default_enemy_data():
	enemy_data = {
		"basic_enemy": {
			"health": 50,
			"speed": 100,
			"damage": 10,
			"xp_reward": 25,
			"attack_range": 30,
			"detection_range": 150,
			"attack_cooldown": 1.0
		}
	}

# Fallback perk data
func create_default_perk_data():
	perk_data = {
		"health_boost": {
			"name": "Health Boost",
			"description": "Increases max health by 20",
			"effect": "max_health",
			"value": 20
		},
		"damage_boost": {
			"name": "Damage Boost", 
			"description": "Increases weapon damage by 25%",
			"effect": "damage_multiplier",
			"value": 1.25
		}
	}

# Difficulty settings (managed at runtime)
var difficulty := "medium"
var _difficulty_multipliers := {"easy": 0.75, "medium": 1.0, "hard": 1.5}

# Set difficulty name
func set_difficulty(name: String) -> void:
	if _difficulty_multipliers.has(name):
		difficulty = name
		print("[BalanceDB] difficulty set to: %s" % name)
	else:
		push_error("Unknown difficulty: %s" % name)

# Damage multiplier for current difficulty
func get_damage_multiplier() -> float:
	return _difficulty_multipliers.get(difficulty, 1.0)

# Current difficulty name
func get_difficulty_name() -> String:
	return difficulty
