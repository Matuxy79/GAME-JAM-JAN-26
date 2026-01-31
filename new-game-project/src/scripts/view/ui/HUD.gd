## HUD script. does game stuff in a simple way.
extends Control
class_name HUD

# HUD screen. Shows health/xp/level/timers and listens for EventBus pings to update quick.

# UI helper
const UI = preload("res://src/scripts/view/ui/UIResourceManager.gd")

# UI bits
@onready var health_bar: ProgressBar = $HealthBar
@onready var xp_bar: ProgressBar = $XPBar
@onready var level_label: Label = $LevelLabel
@onready var mechanics: HBoxContainer = $Mechanics
@onready var stats_panel: TextureRect = $StatsPanel
@onready var stats_container: VBoxContainer = $StatsPanel/StatsContainer

# Powerup slots
var powerup_slots: Array[ColorRect] = []
var powerup_slot_count: int = 4 # Number of powerup display slots
var active_powerups_count: int = 0

# Timer for stat updates
var stats_update_timer: float = 0.0

func _ready():
	print("HUD initialized")
	# Set styles and layout
	setup_styles()
	# Build stats list
	setup_stats_display()
	# Hook signals
	setup_signals()

func _process(delta):
	# Update stats every half second
	stats_update_timer += delta
	if stats_update_timer >= 0.5:  # Update every 0.5 seconds
		stats_update_timer = 0.0
		_update_all_stats()

# Style bars and panels
func setup_styles():
	# Health bar look
	if health_bar:
		var health_styles = UI.progress_style("health_bg", "health_fill")
		# Make sure textures loaded
		if health_styles.background.texture == null:
			push_error("HUD: health_bg texture is null! Path: " + UI.paths.get("health_bg", "unknown"))
		if health_styles.fill.texture == null:
			push_error("HUD: health_fill texture is null! Path: " + UI.paths.get("health_fill", "unknown"))
		# Apply styles
		health_bar.add_theme_stylebox_override("background", health_styles.background)
		health_bar.add_theme_stylebox_override("fill", health_styles.fill)
	
	# XP bar look
	if xp_bar:
		var xp_styles = UI.progress_style("xp_bg", "xp_fill")
		# Make sure textures loaded
		if xp_styles.background.texture == null:
			push_error("HUD: xp_bg texture is null! Path: " + UI.paths.get("xp_bg", "unknown"))
		if xp_styles.fill.texture == null:
			push_error("HUD: xp_fill texture is null! Path: " + UI.paths.get("xp_fill", "unknown"))
		# Apply styles
		xp_bar.add_theme_stylebox_override("background", xp_styles.background)
		xp_bar.add_theme_stylebox_override("fill", xp_styles.fill)
	
	# Rebuild mechanic buttons
	if mechanics:
		# Clear old ones
		for child in mechanics.get_children():
			child.queue_free()
		# Add attack button
		_add_mechanic_button("btn_attack", "attack")
	
	# Stats panel art
	if stats_panel:
		var stats_texture = UI.tex("stats_sheet")
		if stats_texture == null:
			push_error("HUD: stats_sheet texture is null! Path: " + UI.paths.get("stats_sheet", "unknown"))
		# Set texture
		stats_panel.texture = stats_texture
		stats_panel.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED

# Make a mechanic button
func _add_mechanic_button(tex_key: String, action: String):
	var button := TextureButton.new()
	# Give it a texture
	UI.apply_button_texture(button, tex_key)
	button.tooltip_text = action
	# On click, fire event
	button.pressed.connect(func():
		EventBus.weapon_fired.emit(action, Vector2.ZERO)
	)
	mechanics.add_child(button)

# Build the stats list
func setup_stats_display():
	if not stats_panel:
		return
	
	# Make stats container if missing
	if not stats_container:
		stats_container = VBoxContainer.new()
		stats_container.name = "StatsContainer"
		stats_container.set_anchors_preset(Control.PRESET_FULL_RECT)
		stats_container.add_theme_constant_override("separation", 4)
		stats_panel.add_child(stats_container)
	
	# Clear old labels
	for child in stats_container.get_children():
		child.queue_free()
	
	# Make labels for key stats
	_create_stat_label("Health: 100 / 100", "health_label")
	_create_stat_label("XP: 0 / 100", "xp_label")
	_create_stat_label("Level: 1", "level_label")
	_create_stat_label("Max Health: 100", "max_health_label")
	_create_stat_label("Damage Multiplier: 1.0x", "damage_label")
	_create_stat_label("Movement Speed: 200", "speed_label")
	
	# Update stats from player
	call_deferred("_update_all_stats")
	# Make powerup slots
	_setup_powerup_slots()

# Make one stat label
func _create_stat_label(text: String, label_name: String):
	var label = Label.new()
	label.name = label_name
	label.text = text
	# Basic style
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color.WHITE)
	stats_container.add_child(label)

# Refresh all stat texts
func _update_all_stats():
	var player = get_tree().get_first_node_in_group("player")
	if not player or not stats_container:
		return
	
	# Grab labels
	var health_label = stats_container.get_node_or_null("health_label")
	var xp_label = stats_container.get_node_or_null("xp_label")
	var level_label = stats_container.get_node_or_null("level_label")
	var max_health_label = stats_container.get_node_or_null("max_health_label")
	var damage_label = stats_container.get_node_or_null("damage_label")
	var speed_label = stats_container.get_node_or_null("speed_label")
	
	# Health text
	if health_label:
		health_label.text = "Health: %.0f / %.0f" % [player.current_health, player.max_health]
	
	# XP text
	if xp_label:
		xp_label.text = "XP: %d / %d" % [player.xp, player.xp_to_next_level]
	
	# Level text
	if level_label:
		level_label.text = "Level: %d" % player.level
	
	# Max health text
	if max_health_label:
		max_health_label.text = "Max Health: %.0f" % player.max_health
	
	# Damage text
	if damage_label and player.weapon_manager:
		# Try BalanceDB multiplier if there
		var multiplier = 1.0
		if Engine.has_singleton("BalanceDB"):
			var balance_db = Engine.get_singleton("BalanceDB")
			if balance_db.has_method("get_damage_multiplier"):
				multiplier = balance_db.get_damage_multiplier()
		else:
			# Else use local
			multiplier = player.weapon_manager.damage_multiplier
		damage_label.text = "Damage Multiplier: %.2fx" % multiplier
	
	# Speed text
	if speed_label and player.movement_component:
		speed_label.text = "Movement Speed: %.0f" % player.movement_component.speed

# Hook signals for UI updates
func setup_signals():
	EventBus.hud_health_updated.connect(_on_health_updated)
	EventBus.hud_xp_updated.connect(_on_xp_updated)
	EventBus.hud_level_updated.connect(_on_level_updated)
	EventBus.powerup_charges_changed.connect(_on_powerup_charges_changed)
	EventBus.powerup_activated.connect(_on_powerup_activated)

# Make powerup squares
func _setup_powerup_slots():
	# Row for slots
	var slots_container = HBoxContainer.new()
	slots_container.name = "PowerUpSlotsContainer"
	slots_container.add_theme_constant_override("separation", 4)
	# Put under stats
	stats_container.add_child(slots_container)
	
	# Make each slot
	for i in range(powerup_slot_count):
		var slot = ColorRect.new()
		slot.name = "PowerUpSlot_%d" % i
		slot.color = Color.DIM_GRAY  # Default empty color
		slot.custom_minimum_size = Vector2(20, 20)
		powerup_slots.append(slot)
		slots_container.add_child(slot)

# Health changed
func _on_health_updated(current: int, maximum: int):
	if health_bar:
		health_bar.max_value = maximum
		health_bar.value = current
	# Refresh stats
	_update_all_stats()

# XP changed
func _on_xp_updated(current: int, required: int):
	if xp_bar:
		xp_bar.max_value = required
		xp_bar.value = current
	# Refresh stats
	_update_all_stats()

# Level changed
func _on_level_updated(level: int):
	if level_label:
		level_label.text = "Level: " + str(level)
	# Refresh stats
	_update_all_stats()

# Powerup charges changed
func _on_powerup_charges_changed(charges: int):
	for i in range(powerup_slot_count):
		if i < charges:
			# Slot filled
			powerup_slots[i].color = Color.GREEN
		else:
			# Empty slot
			powerup_slots[i].color = Color.DIM_GRAY

# Powerup got used, fade a slot
func _on_powerup_activated(duration: float):
	# Find the last green slot
	for i in range(powerup_slot_count - 1, -1, -1):
		if powerup_slots[i].color == Color.GREEN:
			# Fade to gray
			var tween = create_tween()
			tween.tween_property(powerup_slots[i], "color", Color.DIM_GRAY, duration)
			break
