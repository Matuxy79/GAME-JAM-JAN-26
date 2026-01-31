# Quick Start (plain and short)

## Get the game running
1) Open Godot 4.5. Import `new-game-project/project.godot`.
2) Set main scene: Project Settings ➜ Application ➜ Main Scene = `res://src/scenes/GameRoot.tscn`.
3) Inputs are already set (move_up/down/left/right, pause, bite, fire). Just check if you want.
4) Press F5. You should see a white player, red enemies chasing, yellow bullets, green XP gems, and health/XP bars.

## Controls
- WASD / Arrows: move
- Space: powerup/weapon switch (mapped to the working powerup flow)
- Escape: pause
- Mouse: aim (if enabled)

## Game objects
- Player: you with the laser/ and special attack spacebar - (laserbeam/laserspikeball)
- Enemies: fast/tank/normal
- Bullets: laser and laserbeam and laserspikeball
- XP gems: green diamonds and powerups for special weapon swaps
- UI: green health bar, blue XP bar and HUD

## If it won’t start
- Make sure main scene is `GameRoot.tscn`.
- Autoloads set in Project Settings (EventBus, Pools, Save, BalanceDB, Rng).
- Check the Output panel for errors.

## If stuff is missing
- No enemies? Check `EnemyManager` and `Pools` autoload.
- No sprites? Make sure sprites are in `assets/sprites/` and imported.
- No movement? Check input map and that `MovementComponent` is on the player scene.

## Quick test list
1) Move with WASD.
2) Watch enemies spawn and chase.
3) See auto-fire bullets.
4) Grab green gems.
5) Watch health/XP bars change.

## Code map (where to look)
- Scenes: `src/scenes/GameRoot.tscn`, `Player.tscn`, `Enemy.tscn`, `UI/HUD.tscn`.
- Autoloads: `src/scripts/controller/autoload/EventBus.gd`, `src/scripts/controller/autoload/Pools.gd`, `src/scripts/model/autoload/BalanceDB.gd`, `Rng.gd`, `Save.gd`.
- Player: `src/scripts/controller/player/Player.gd` (+ movement/health/weapon parts under `src/scripts/model/player/`).
- Enemies: `src/scripts/model/enemy/Enemy.gd`, manager at `src/scripts/controller/enemy/EnemyManager.gd`.
- Loot: `src/scripts/controller/loot/LootManager.gd`, `ProjectileManager.gd`; items under `src/scripts/model/loot/`.
- UI: `src/scripts/view/ui/HUD.gd` plus other UI scenes.
- Data: `src/resources/data/*.json` (weapons, enemies, powerups, perks, xp_curve).

## Next tweaks (optional)
- Add collisions/animations/sound to make it feel nicer.
- Tune JSON data to change balance without code.
