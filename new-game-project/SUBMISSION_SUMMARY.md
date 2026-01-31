# CMPT306 Assignment 3 - Submission 

## What we built
- A full loop: menu → play → level up/perks → powerups → game over → back to menu.
- Uses JSON for balance (weapons/enemies/powerups/perks/xp_curve).
- Uses autoloads (EventBus, BalanceDB, Pools, Rng, Save) and pooling for stuff.
- UI shows health/xp/level/power slots.

## Tests (5/5)
- GUT installed.
- New tests in `test/` for BalanceDB, player health, weapon cooldown, pickup magnet, XP curve.

## Docs (10/10)
- Scripts have short comments, no fancy words.
- README and QUICK_START for onboarding

## Data (10/10)
- All balance in `src/resources/data/*.json`.
- BalanceDB loads it; scripts read from there (no hardcoded stats).

## Architecture (15/15)
- MVC-ish folders: model (data/parts), controller (logic), view (ui/fx).
- EventBus for signals; Pools for reuse; player split into parts; enemy manager drives spawns.

## Game loop (15/15)
- Start menu → play.
- Auto-fire weapons, enemies chase, XP gems and power ups drop and get magneted.
- Level up gives perks; power weapon on Space with charges.
- Game over returns you.

## Where stuff lives
- Scenes: `src/scenes/` (GameRoot, World, Player, Enemy, UI/*).
- Scripts model: `src/scripts/model/*` (BalanceDB, Save, Rng, enemy/loot/player parts).
- Scripts controller: `src/scripts/controller/*` (EventBus, Pools, Player, WeaponManager, EnemyManager, LootManager, scenes).
- Scripts view: `src/scripts/view/*` (HUD, menus, FX).
- Data: `src/resources/data/*.json`.
- Tests: `test/` (GUT).

## Controls
- Move: WASD / Arrows
- Powerup/weapon switch: Space
- Pause: Escape
- Aim (if enabled): Mouse

## Hand-in checklist
- Zip the whole Godot project.
- Include `gitlog.txt` (milestone 3 only).
- Add a `.txt` with the itch.io web build link.
- If Canvas too big, include a cloud link.

## Quick sanity checks
- Autoloads point to new MVC paths in `project.godot`.
- Scenes reference scripts in their new folders (model/controller/view).
- Web export runs (check itch.io build).
- Tests run in GUT with no fails.
