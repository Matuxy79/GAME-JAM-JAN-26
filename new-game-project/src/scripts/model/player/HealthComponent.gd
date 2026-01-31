## HealthComponent script. does game stuff in a simple way.
extends Node
class_name HealthComponent

# Health blob for a character. Takes damage, heals, and yells when it dies.

signal health_changed(new_health: int, max_health: int)
signal died
signal damage_taken(amount: int)
signal healed(amount: int)

@export var max_health: int = 100
@export var current_health: int = 100
@export var invulnerability_duration: float = 1.0

var is_invulnerable: bool = false
var invulnerability_timer: float = 0.0

func _ready():
	current_health = max_health
	print("HealthComponent initialized - Health: ", current_health, "/", max_health)

func _process(delta):
	if is_invulnerable:
		invulnerability_timer -= delta
		if invulnerability_timer <= 0:
			is_invulnerable = false

func take_damage(amount: int):
	if is_invulnerable or current_health <= 0:
		return
	
	current_health = max(0, current_health - amount)
	damage_taken.emit(amount)
	health_changed.emit(current_health, max_health)
	
	# Start invulnerability period
	start_invulnerability()
	
	# Check for death
	if current_health <= 0:
		die()

func heal(amount: int):
	if current_health <= 0:
		return
	
	var old_health = current_health
	current_health = min(max_health, current_health + amount)
	var actual_healing = current_health - old_health
	
	if actual_healing > 0:
		healed.emit(actual_healing)
		health_changed.emit(current_health, max_health)

func die():
	if current_health > 0:
		current_health = 0
		health_changed.emit(current_health, max_health)
	
	died.emit()
	print("Player died!")

func start_invulnerability():
	is_invulnerable = true
	invulnerability_timer = invulnerability_duration

func set_max_health(new_max_health: int):
	max_health = new_max_health
	current_health = min(current_health, max_health)
	health_changed.emit(current_health, max_health)

func get_health_percentage() -> float:
	if max_health <= 0:
		return 0.0
	return float(current_health) / float(max_health)

func is_alive() -> bool:
	return current_health > 0

func is_at_full_health() -> bool:
	return current_health >= max_health
