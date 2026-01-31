# Vampire Survival Game

## What this is
A top-down survival game in Godot 4.5. You run around, alien squid survival, you auto-shoot, grab XP gems, pick perks, and sometimes pop a power weapon.

## How to run
1) Open Godot 4.5. Import `project.godot`.
2) Set main scene: Project Settings → Application → Main Scene = `res://src/scenes/GameRoot.tscn`.
3) Inputs are already set. Hit Play (F5).

## Controls
- Move: WASD / Arrows
- Powerup/weapon switch: Space
- Pause: Escape
- Aim (if used): Mouse

## Where stuff lives (simple map)
- Scenes: `src/scenes/` (GameRoot, Player, Enemy, World, UI/*)
- Scripts:
  - Model/data-ish: `src/scripts/model/*` (BalanceDB, Save, Rng, enemy, loot items, player parts)
  - Controllers: `src/scripts/controller/*` (EventBus, Pools, Player, WeaponManager, EnemyManager, LootManager, scenes)
  - Views/UI: `src/scripts/view/*` (HUD, menus, FX)
- Data: `src/resources/data/*.json` (weapons, enemies, powerups, perks, xp_curve)
- Tests: `test/` (GUT)

## What it does
- Auto-fire weapons with projectiles
- Enemies spawn and chase
- XP gems drop; magnet pulls them in
- Level up and pick perks
- Power weapon mode when you hit Space with a charge
- UI shows health/xp/level/power slots

## Gotchas / checks
- Autoloads in Project Settings: EventBus, Pools, BalanceDB, Rng, Save (paths match the controller/model folders).
- If nothing moves: check input map.
- If enemies missing: check EnemyManager node in `World.tscn` and Pools autoload.
- If sprites missing: make sure assets are imported.

## Files you may open first
- `src/scripts/controller/player/Player.gd` (player brain)
- `src/scripts/controller/player/WeaponManager.gd` (auto-fire)
- `src/scripts/model/loot/XPGem.gd` (XP pickup)
- `src/scripts/controller/enemy/EnemyManager.gd` (spawns)
- `src/scripts/view/ui/HUD.gd` (UI)
- `src/resources/data/*.json` (tweak numbers)

## Next things to polish (optional)
- Add sounds/animations
- Tune JSON balance
- More enemy types or waves
- More tests in `test/`
