# Colony Mode Modding

Colony mode is data-driven. Pawns, abilities, resources and the cosmology
events are all plain JSON "defs" loaded by the `DefDatabase` autoload at boot.
You can change numbers, add new content, or override core content without
touching a single script.

## Where defs live

- **Core defs**: `res://src/resources/defs/*.json` (ships with the game)
- **Mods**: `user://mods/<your_mod_name>/defs/*.json`

On Windows, `user://` is `%APPDATA%\Godot\app_userdata\Vamp-Survival\`.
On iOS (Xogot), it is the app's documents sandbox.

Load order: core first, then each mod folder in alphabetical order. When two
files define the same def id of the same type, **the later one wins**. That is
how mods override core content.

## File format

Every def file is one JSON object with a `type` and a `defs` dictionary:

```json
{
  "type": "abilities",
  "defs": {
    "my_new_move": {
      "name": "My New Move",
      "damage": 20,
      "range": 40.0,
      "arc_degrees": 120.0,
      "cooldown_ticks": 15,
      "startup_ticks": 4,
      "active_ticks": 2,
      "recovery_ticks": 6,
      "knockback": 90.0,
      "hitstun_ticks": 5,
      "hit_stop_seconds": 0.06,
      "afterimage": true,
      "swing_color": "#a2ffd1"
    }
  }
}
```

Bad files are skipped with an error in the output log (`DefDatabase.load_errors`
holds them at runtime); the game keeps loading everything else.

## Def types

### `pawns`
Colonists and hostiles. Key fields: `name`, `faction` (`colony`/`raider`),
`max_health`, `move_speed`, `color`, `radius`, `abilities` (array of ability
ids), `needs` (decay rates and thresholds), `work` (`harvest_ticks`,
`carry_capacity`).

### `abilities`
FGC-style frame data, in sim ticks (10 ticks = 1 second at 1x speed):
`startup_ticks` (wind-up), `active_ticks` (hitbox out), `recovery_ticks`
(whiff punish window), plus `damage`, `range`, `arc_degrees`, `cooldown_ticks`,
`knockback`, `hitstun_ticks`, `hit_stop_seconds` and the anime flair flags
`afterimage` / `swing_color`.

### `resources`
Harvestable map nodes: `yields` (`food`/`wood`/`exotic`), `yield_amount`,
`max_stock`, `regrow_per_tick`, `color`.

### `cosmology`
The Brief History of Time layer:
- `entropy`: how fast disorder rises and how often anomaly checks roll.
- `black_hole`: radii, pull strength, lifetime, Hawking `shard_drops`.
- `time_dilation`: zone radius, local `time_scale`, lifetime.
- `entropy_surge`: raid sizes, scaled by current entropy.

`black_hole`, `time_dilation` and `entropy_surge` carry a `weight` field used
for the random pick when an event fires.

## Example mod

`user://mods/glass_cannon/defs/pawns.json`:

```json
{
  "type": "pawns",
  "defs": {
    "colonist": {
      "name": "Glass Cannon",
      "faction": "colony",
      "max_health": 40,
      "move_speed": 130.0,
      "color": "#ffde59",
      "radius": 9.0,
      "abilities": ["heavy_cleave", "quick_slash"],
      "needs": {
        "hunger_decay_per_tick": 0.06,
        "rest_decay_per_tick": 0.04,
        "hunger_eat_threshold": 35.0,
        "rest_sleep_threshold": 25.0,
        "starvation_damage_per_tick": 1.0,
        "eat_restore": 70.0,
        "sleep_restore_per_tick": 0.6
      },
      "work": { "harvest_ticks": 14, "carry_capacity": 5 }
    }
  }
}
```

This overrides the core colonist because the id (`colonist`) matches.
