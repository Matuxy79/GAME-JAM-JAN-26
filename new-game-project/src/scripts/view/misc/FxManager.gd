## FxManager script. does game stuff in a simple way.
extends Node
class_name FxManager

# FxManager - Handles visual and audio effects
# Manages particles, sounds, and screen effects

@export var particle_scenes: Dictionary = {}
@export var sound_effects: Dictionary = {}

var active_particles: Array[Node2D] = []

func _ready():
	print("FxManager initialized")
	setup_signals()
	load_effect_resources()

func setup():
	print("FxManager setup")
	setup_signals()

func setup_signals():
	# Connect to EventBus signals for automatic effect triggering
	if not EventBus.projectile_hit.is_connected(_on_projectile_hit):
		EventBus.projectile_hit.connect(_on_projectile_hit)
	if not EventBus.enemy_died.is_connected(_on_enemy_died):
		EventBus.enemy_died.connect(_on_enemy_died)
	if not EventBus.xp_gem_collected.is_connected(_on_xp_gem_collected):
		EventBus.xp_gem_collected.connect(_on_xp_gem_collected)
	if not EventBus.player_died.is_connected(_on_player_died):
		EventBus.player_died.connect(_on_player_died)

func load_effect_resources():
	# Load particle scenes and sound effects
	# This would typically load from resource files
	particle_scenes = {
		"hit_effect": null,  # Would load actual particle scene
		"explosion": null,
		"xp_collect": null
	}
	
	sound_effects = {
		"hit": null,  # Would load actual audio stream
		"explosion": null,
		"xp_collect": null,
		"weapon_fire": null
	}

func _on_projectile_hit(target: Node2D, _damage: int):
	# Play hit effect at target position
	play_hit_effect(target.global_position)

func _on_enemy_died(_enemy: Enemy, position: Vector2):
	# Play death effect
	play_explosion_effect(position)

func _on_xp_gem_collected(_amount: int):
	# Play collection effect
	play_xp_collect_effect()

func _on_player_died():
	# Play death screen effect
	play_death_effect()

func play_hit_effect(position: Vector2):
	print("Playing hit effect at ", position)
	# In a real implementation, this would spawn a particle effect
	# var hit_particle = particle_scenes["hit_effect"].instantiate()
	# hit_particle.global_position = position
	# get_tree().current_scene.add_child(hit_particle)

func play_explosion_effect(position: Vector2):
	print("Playing explosion effect at ", position)
	# In a real implementation, this would spawn an explosion particle
	# var explosion = particle_scenes["explosion"].instantiate()
	# explosion.global_position = position
	# get_tree().current_scene.add_child(explosion)

func play_xp_collect_effect():
	print("Playing XP collect effect")
	# In a real implementation, this would play a sound and show a visual effect
	# play_sound("xp_collect")

func play_death_effect():
	print("Playing death effect")
	# In a real implementation, this would show a death screen effect
	# play_sound("player_death")

func play_sound(sound_name: String):
	if sound_name in sound_effects:
		print("Playing sound: ", sound_name)
		# In a real implementation, this would play the actual sound
		# var audio_player = AudioStreamPlayer.new()
		# audio_player.stream = sound_effects[sound_name]
		# add_child(audio_player)
		# audio_player.play()

func play_particle_effect(effect_name: String, position: Vector2):
	if effect_name in particle_scenes:
		print("Playing particle effect: ", effect_name, " at ", position)
		# In a real implementation, this would spawn the particle effect
		# var particle = particle_scenes[effect_name].instantiate()
		# particle.global_position = position
		# get_tree().current_scene.add_child(particle)
		# active_particles.append(particle)

func cleanup_particles():
	# Clean up finished particle effects
	for particle in active_particles:
		if particle and is_instance_valid(particle):
			if not particle.emitting:
				particle.queue_free()
				active_particles.erase(particle)

func screen_shake(intensity: float, duration: float):
	print("Screen shake: intensity=", intensity, " duration=", duration)
	# In a real implementation, this would shake the camera
	# var camera = get_viewport().get_camera_2d()
	# if camera:
	#     camera.add_trauma(intensity, duration)
