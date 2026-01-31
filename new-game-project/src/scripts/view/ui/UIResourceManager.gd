## UIResourceManager script. does game stuff in a simple way.
extends Node
class_name UIResourceManager

# UIResourceManager - Centralized UI texture and style management
# Replaces UIRegions.gd with individual PNG texture loading
# Provides helper methods for creating UI styles from individual textures

# Texture path dictionary
const paths := {
	"background": "res://assets/sprites/ui/background.png",
	"health_bg": "res://assets/sprites/ui/health_bar/health_bar_bg.png",
	"health_fill": "res://assets/sprites/ui/health_bar/health_bar_fill.png",
	"xp_bg": "res://assets/sprites/ui/xp_bar/xp_bar_bg.png",
	"xp_fill": "res://assets/sprites/ui/xp_bar/xp_bar_fill.png",
	"panel_bg": "res://assets/sprites/ui/panels/panel_bg.png",
	"stats_sheet": "res://assets/sprites/ui/stats-sheet.png",
	"btn_attack": "res://assets/sprites/ui/mechanics/attack.png",
}

# Load a texture by key
static func tex(key: String) -> Texture2D:
	if key in paths:
		var texture = load(paths[key]) as Texture2D
		if texture == null:
			push_warning("UIResourceManager: Failed to load texture: " + paths[key])
		return texture
	push_error("UIResourceManager: Unknown texture key: " + key)
	return null

# Create progress bar styles (background and fill)
static func progress_style(bg_key: String, fill_key: String) -> Dictionary:
	var result := {}
	
	# Load textures with validation
	var bg_texture = tex(bg_key)
	var fill_texture = tex(fill_key)
	
	# Report errors if textures failed to load
	if bg_texture == null:
		push_error("UIResourceManager: progress_style() - bg_texture is null for key: " + bg_key + " (Path: " + paths.get(bg_key, "unknown") + ")")
	if fill_texture == null:
		push_error("UIResourceManager: progress_style() - fill_texture is null for key: " + fill_key + " (Path: " + paths.get(fill_key, "unknown") + ")")
	
	# Background style
	var bg_style := StyleBoxTexture.new()
	bg_style.texture = bg_texture
	bg_style.draw_center = true
	result["background"] = bg_style
	
	# Fill style
	var fill_style := StyleBoxTexture.new()
	fill_style.texture = fill_texture
	fill_style.draw_center = true
	result["fill"] = fill_style
	
	return result

# Create panel style with 9-slice margins
static func panel_style(key: String, margins: Vector4) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = tex(key)
	sb.content_margin_left = margins.x
	sb.content_margin_top = margins.y
	sb.content_margin_right = margins.z
	sb.content_margin_bottom = margins.w
	sb.draw_center = true
	return sb

# Create button style with 9-slice margins
static func button_style(key: String, margins: Vector4) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = tex(key)
	sb.content_margin_left = margins.x
	sb.content_margin_top = margins.y
	sb.content_margin_right = margins.z
	sb.content_margin_bottom = margins.w
	sb.draw_center = true
	return sb

# Apply texture to TextureButton
static func apply_button_texture(button: TextureButton, tex_key: String) -> void:
	if button == null:
		return
	var texture = tex(tex_key)
	if texture:
		button.texture_normal = texture
		button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	else:
		push_error("UIResourceManager: Failed to apply texture '" + tex_key + "' to button (Path: " + paths.get(tex_key, "unknown") + ")")

# Apply button styles (normal, hover, pressed)
# Uses same texture for all states if only one provided, or separate textures if available
static func apply_button_styles(button: Button, margins: Vector4 = Vector4(16, 16, 16, 16)) -> void:
	if button == null:
		return
	
	# For now, use panel_bg for all button states
	# In the future, can add button_normal, button_hover, button_pressed textures
	var normal_style := panel_style("panel_bg", margins)
	var hover_style := panel_style("panel_bg", margins)
	var pressed_style := panel_style("panel_bg", margins)
	
	button.add_theme_stylebox_override("normal", normal_style)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("pressed", pressed_style)
	button.add_theme_stylebox_override("focus", hover_style)
