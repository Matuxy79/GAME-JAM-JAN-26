# Game Sprites Documentation

This directory contains all visual assets for the Vampire Survival game.

## Directory Structure

```
assets/sprites/
├── player/          # Player character sprites
├── enemies/         # Enemy character sprites  
├── weapons/         # Weapon and projectile sprites
├── loot/            # Collectible item sprites
└── ui/              # User interface sprites
```

## Current Sprites (SVG Format)

### Player Sprites
- **`player_idle.svg`** (32x32) - White character with black outline
  - Used in: `Player.tscn`
  - Features: Simple humanoid shape with head, body, arms, legs

### Enemy Sprites
- **`enemy_basic.svg`** (32x32) - Red character with fangs
  - Used in: `Enemy.tscn` (default enemy type)
  - Features: Angry expression, vampire fangs
  
- **`enemy_fast.svg`** (24x24) - Blue character with speed lines
  - Used in: Enemy spawning system
  - Features: Smaller size, speed indicators
  
- **`enemy_tank.svg`** (40x40) - Dark red character with armor
  - Used in: Enemy spawning system  
  - Features: Larger size, armor plates

### Weapon Sprites
- **`bullet.svg`** (8x8) - Yellow circular projectile
  - Used in: `Projectile.tscn`
  - Features: Simple bullet with golden center
  
- **`laser_beam.svg`** (16x4) - Cyan rectangular laser
  - Used in: `Projectile.tscn` (alternative weapon)
  - Features: Energy beam appearance

### Loot Sprites
- **`xp_gem.svg`** (16x16) - Green diamond-shaped gem
  - Used in: `XPGem.tscn`
  - Features: Diamond shape with sparkle effect

### UI Sprites
- **`health_bar_bg.svg`** (200x20) - Dark gray health bar background
- **`health_bar_fill.svg`** (200x20) - Bright green health bar fill
- **`xp_bar_bg.svg`** (200x20) - Dark gray XP bar background  
- **`xp_bar_fill.svg`** (200x20) - Bright blue XP bar fill
  - Used in: `HUD.tscn` progress bars

## Sprite Specifications

### Technical Requirements
- **Format**: SVG (Scalable Vector Graphics)
- **Color Depth**: RGB with transparency support
- **Size**: Power of 2 dimensions for optimal performance
- **Naming**: snake_case convention

### Color Scheme
- **Player**: White (#FFFFFF) with black outlines
- **Enemies**: Red (#FF0000), Blue (#0088FF), Dark Red (#8B0000)
- **Projectiles**: Yellow (#FFFF00), Cyan (#00FFFF)
- **XP Gems**: Green (#00FF00) with highlights
- **UI**: Dark backgrounds (#333333) with bright accents

## Usage in Godot

### Importing Sprites
1. SVG files are automatically imported by Godot
2. They appear in the FileSystem dock under `assets/sprites/`
3. Drag and drop onto Sprite2D nodes to assign textures

### Scene Integration
All scene files (`.tscn`) are pre-configured with sprite references:
- `Player.tscn` → `player_idle.svg`
- `Enemy.tscn` → `enemy_basic.svg`
- `XPGem.tscn` → `xp_gem.svg`
- `Projectile.tscn` → `bullet.svg`

### Replacing Sprites
To replace with custom sprites:
1. Create new PNG/SVG file with same name
2. Place in appropriate subdirectory
3. Godot will automatically update references
4. Or manually reassign in scene editor

## Development Notes

### Why SVG?
- **Scalable**: Works at any resolution
- **Small file size**: Text-based format
- **Easy to edit**: Can be modified with text editor
- **Godot compatible**: Native SVG import support

### Performance Considerations
- SVG files are converted to textures at import time
- No runtime performance impact
- Consider converting to PNG for final builds if needed

### Future Enhancements
- Add animation frames for walking, attacking
- Create particle effects for explosions, hits
- Add more enemy variants and weapon types
- Implement sprite atlases for better performance

## Troubleshooting

### Sprites Not Showing
1. Check file paths in scene files
2. Ensure SVG files are in correct directories
3. Verify Godot has imported the files (check FileSystem dock)
4. Check for typos in file names

### Performance Issues
1. Consider using PNG instead of SVG for complex sprites
2. Use sprite atlases for many small sprites
3. Enable texture compression in Project Settings

### Custom Sprites
1. Maintain same dimensions as original sprites
2. Use consistent color scheme
3. Follow naming conventions
4. Test in game to ensure proper scaling
