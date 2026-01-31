## EventBus script. does game stuff in a simple way.
@warning_ignore("unused_signal")
extends Node

# Event bus. All the game signals live here so stuff can talk without direct refs.

# Player signals - triggered when player state changes
signal player_health_changed(new_health: int, max_health: int)
signal player_died
signal player_level_up(new_level: int)
signal player_xp_gained(amount: int)
signal player_moved(position: Vector2)

# Enemy signals - triggered when enemy events occur
signal enemy_spawned(enemy: Node2D)
signal enemy_died(enemy: Node2D, position: Vector2)
signal enemy_damaged(enemy: Node2D, damage: int)

# Combat signals - triggered during combat interactions
signal projectile_fired(projectile: Node2D, direction: Vector2)
signal projectile_hit(target: Node2D, damage: int)
signal weapon_fired(weapon_name: String, direction: Vector2)

# Loot signals - triggered when loot is collected or dropped
signal xp_gem_collected(amount: int)
signal loot_dropped(loot_type: String, position: Vector2)
signal powerup_collected(duration: float)

# Game state signals - triggered for major game state changes
signal game_started
signal game_paused
signal game_resumed
signal resume_requested
signal game_over(final_score: int)
signal level_up_available(perks: Array)

# UI signals - triggered to update user interface elements
signal hud_health_updated(current: int, maximum: int)
signal hud_xp_updated(current: int, required: int)
signal hud_level_updated(level: int)
signal show_level_up_modal(perks: Array)
signal show_powerup_choice_modal(powerups: Array)
signal powerup_charges_changed(charges: int)
signal powerup_activated(duration: float)

# World signals - triggered for world/environment events
signal time_of_day_changed(hour: int)
signal sunlight_damage_tick(damage: int)

func _ready():
	print("EventBus initialized")

# Quick check to see if a signal is hooked up
func validate_signal_connection(signal_name: String, target: Node, method: String) -> bool:
	if not has_signal(signal_name):
		push_error("EventBus: Signal '%s' does not exist" % signal_name)
		return false
	if not target.is_connected(signal_name, Callable(target, method)):
		push_error("EventBus: Failed to connect signal '%s' to %s.%s" % [signal_name, target.name, method])
		return false
	return true
