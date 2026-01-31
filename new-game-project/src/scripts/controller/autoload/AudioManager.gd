## AudioManager - Centralized audio system for the game
extends Node

# Audio player pools for different sound types
var sfx_players: Array[AudioStreamPlayer] = []
var music_player: AudioStreamPlayer = null

# Configuration
@export var max_sfx_players: int = 10
@export var master_volume: float = 1.0
@export var sfx_volume: float = 1.0
@export var music_volume: float = 0.7

# Sound library - maps sound names to AudioStream resources
var sound_library: Dictionary = {}

func _ready():
	print("AudioManager initialized")
	setup_audio_players()
	setup_signals()
	load_sounds()

func setup_audio_players():
	# Create a pool of AudioStreamPlayer nodes for SFX
	for i in range(max_sfx_players):
		var player = AudioStreamPlayer.new()
		player.name = "SFXPlayer_" + str(i)
		player.bus = "SFX"  # Uses "SFX" audio bus (create in Audio Bus Layout)
		add_child(player)
		sfx_players.append(player)
	
	# Create dedicated music player
	music_player = AudioStreamPlayer.new()
	music_player.name = "MusicPlayer"
	music_player.bus = "Music"  # Uses "Music" audio bus
	add_child(music_player)
	
	print("Audio players created: ", sfx_players.size(), " SFX players")

func setup_signals():
	# Connect to EventBus for automatic sound triggering
	EventBus.weapon_fired.connect(_on_weapon_fired)
	EventBus.projectile_hit.connect(_on_projectile_hit)
	EventBus.enemy_died.connect(_on_enemy_died)
	EventBus.xp_gem_collected.connect(_on_xp_collected)
	EventBus.player_health_changed.connect(_on_player_health_changed)
	EventBus.player_died.connect(_on_player_died)
	EventBus.player_level_up.connect(_on_player_level_up)
	EventBus.powerup_collected.connect(_on_powerup_collected)

func load_sounds():
	# Load all your audio files here
	sound_library = {
		# Combat sounds
		"shoot": load("res://assets/Sounds/shoot-b.ogg"),
		"hit": null,    # Add: load("res://assets/Sounds/hit.ogg")
		"explosion": null,  # Add: load("res://assets/Sounds/explosion.ogg")
		
		# Player sounds
		"player_hurt": null,  # Add: load("res://assets/Sounds/hurt.ogg")
		"player_death": null,  # Add: load("res://assets/Sounds/death.ogg")
		"level_up": null,  # Add: load("res://assets/Sounds/level_up.ogg")
		
		# Pickup sounds
		"xp_collect": null,  # Add: load("res://assets/Sounds/xp_collect.ogg")
		"powerup": null,  # Add: load("res://assets/Sounds/powerup.ogg")
		
		# UI sounds
		"button_click": null,  # Add: load("res://assets/Sounds/click.ogg")
		"menu_open": null,  # Add: load("res://assets/Sounds/menu.ogg")
	}
	
	print("Sound library initialized with ", sound_library.size(), " entries")

# Play a sound effect by name
func play_sfx(sound_name: String, volume_db: float = 0.0, pitch_scale: float = 1.0):
	if not sound_name in sound_library:
		push_warning("Sound not found in library: " + sound_name)
		return
	
	var sound_stream = sound_library[sound_name]
	if sound_stream == null:
		# Sound not loaded yet - just log it
		print("Playing sound: ", sound_name, " (not loaded)")
		return
	
	# Find an available player
	var player = _get_available_sfx_player()
	if player == null:
		push_warning("No available audio player for: " + sound_name)
		return
	
	# Configure and play
	player.stream = sound_stream
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	player.play()

# Play music (looping)
func play_music(music_stream: AudioStream, fade_in_duration: float = 0.0):
	if music_player.playing:
		stop_music(fade_in_duration)
	
	music_player.stream = music_stream
	music_player.volume_db = linear_to_db(music_volume)
	
	if fade_in_duration > 0:
		music_player.volume_db = -80  # Start silent
		music_player.play()
		# Fade in
		var tween = create_tween()
		tween.tween_property(music_player, "volume_db", linear_to_db(music_volume), fade_in_duration)
	else:
		music_player.play()

# Stop music
func stop_music(fade_out_duration: float = 0.0):
	if fade_out_duration > 0:
		var tween = create_tween()
		tween.tween_property(music_player, "volume_db", -80, fade_out_duration)
		tween.tween_callback(music_player.stop)
	else:
		music_player.stop()

# Set volume levels
func set_master_volume(volume: float):
	master_volume = clamp(volume, 0.0, 1.0)
	AudioServer.set_bus_volume_db(0, linear_to_db(master_volume))

func set_sfx_volume(volume: float):
	sfx_volume = clamp(volume, 0.0, 1.0)
	var bus_idx = AudioServer.get_bus_index("SFX")
	if bus_idx >= 0:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(sfx_volume))

func set_music_volume(volume: float):
	music_volume = clamp(volume, 0.0, 1.0)
	var bus_idx = AudioServer.get_bus_index("Music")
	if bus_idx >= 0:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(music_volume))
	if music_player and music_player.playing:
		music_player.volume_db = linear_to_db(music_volume)

# Get an available SFX player from the pool
func _get_available_sfx_player() -> AudioStreamPlayer:
	for player in sfx_players:
		if not player.playing:
			return player
	# If all players busy, return the first one (it will interrupt)
	return sfx_players[0] if sfx_players.size() > 0 else null

# === Signal Handlers ===

func _on_weapon_fired(_weapon_name: String, _direction: Vector2):
	play_sfx("shoot", -5.0, randf_range(0.9, 1.1))  # Random pitch variation

func _on_projectile_hit(_target: Node2D, _damage: int):
	play_sfx("hit", -3.0, randf_range(0.95, 1.05))

func _on_enemy_died(_enemy: Node2D, _position: Vector2):
	play_sfx("explosion", 0.0, randf_range(0.8, 1.2))

func _on_xp_collected(_amount: int):
	play_sfx("xp_collect", -8.0, randf_range(1.0, 1.3))  # Higher pitch for XP

func _on_player_health_changed(_new_health: int, _max_health: int):
	play_sfx("player_hurt", -2.0)

func _on_player_died():
	play_sfx("player_death", 2.0, 0.8)  # Louder, lower pitch

func _on_player_level_up(_new_level: int):
	play_sfx("level_up", 0.0)

func _on_powerup_collected(_duration: float):
	play_sfx("powerup", 0.0, 1.1)

# Utility: Play UI sounds (for buttons, menus, etc.)
func play_ui_sound(sound_name: String):
	play_sfx(sound_name, -10.0)  # UI sounds typically quieter
