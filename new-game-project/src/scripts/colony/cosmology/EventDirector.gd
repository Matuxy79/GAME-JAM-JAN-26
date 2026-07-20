## EventDirector script. does game stuff in a simple way.
extends Node
class_name EventDirector

# The Brief History of Time layer. Entropy only ever rises (second law), and
# the higher it climbs the more often spacetime misbehaves: micro black holes,
# time dilation zones, and entropy-surge raids. All numbers live in the
# "cosmology" defs so mods can rewrite the laws of physics.

var grid: ColonyGrid
var pawn_container: Node2D
var entropy: float = 0.0

var _entropy_def: Dictionary = {}

# Wire world refs (ColonyRoot calls this)
func setup(colony_grid: ColonyGrid, pawns: Node2D) -> void:
	grid = colony_grid
	pawn_container = pawns
	_entropy_def = DefDatabase.get_def("cosmology", "entropy")

func _ready():
	SimClock.sim_tick.connect(_on_sim_tick)

# Entropy rises every tick; periodically roll for an anomaly
func _on_sim_tick(tick: int) -> void:
	if _entropy_def.is_empty():
		return
	var colonists := _count_colonists()
	var rise := float(_entropy_def.get("base_rise_per_tick", 0.004))
	rise += float(_entropy_def.get("rise_per_colonist_per_tick", 0.0008)) * float(colonists)
	entropy = clampf(entropy + rise, 0.0, 100.0)
	if tick % 10 == 0:
		EventBus.entropy_changed.emit(entropy)

	var interval := int(_entropy_def.get("event_check_interval_ticks", 120))
	if interval > 0 and tick % interval == 0 and tick > 0:
		var chance := lerpf(
			float(_entropy_def.get("event_chance_at_zero", 0.02)),
			float(_entropy_def.get("event_chance_at_max", 0.5)),
			entropy / 100.0)
		if randf() < chance:
			_fire_random_event()

# Weighted pick among the anomaly defs, then make it happen
func _fire_random_event() -> void:
	var candidates: Array[String] = ["black_hole", "time_dilation", "entropy_surge"]
	var total := 0.0
	var weights: Array[float] = []
	for id in candidates:
		var w := float(DefDatabase.get_def("cosmology", id).get("weight", 1))
		weights.append(w)
		total += w
	var roll := randf() * total
	for i in range(candidates.size()):
		roll -= weights[i]
		if roll <= 0.0:
			_fire_event(candidates[i])
			return

# Spawn the chosen anomaly
func _fire_event(id: String) -> void:
	var def: Dictionary = DefDatabase.get_def("cosmology", id)
	match id:
		"black_hole":
			var hole := ColonyBlackHole.new()
			hole.setup(def, grid, self)
			hole.position = grid.cell_to_world(grid.random_walkable_cell())
			pawn_container.get_parent().add_child(hole)
			EventBus.cosmology_event.emit(str(def.get("name", id)), hole.position)
		"time_dilation":
			var zone := TimeDilationZone.new()
			zone.setup(def)
			zone.position = grid.cell_to_world(grid.random_walkable_cell())
			pawn_container.get_parent().add_child(zone)
			EventBus.cosmology_event.emit(str(def.get("name", id)), zone.position)
		"entropy_surge":
			_spawn_raid(def)

# Raiders pour in at the map edge, scaled by entropy
func _spawn_raid(def: Dictionary) -> void:
	var count := randi_range(int(def.get("raiders_min", 1)), int(def.get("raiders_max", 3)))
	count += int(entropy / 25.0) * int(def.get("raiders_per_25_entropy", 1))
	var root := pawn_container.get_parent()
	for _i in range(count):
		if not root.has_method("spawn_pawn"):
			return
		var cell: Vector2i = grid.random_edge_cell()
		root.spawn_pawn("raider", grid.cell_to_world(cell))
	EventBus.raid_started.emit(count)
	EventBus.cosmology_event.emit(str(def.get("name", "Entropy Surge")), grid.map_center())

# Black holes evaporating gives a little order back (poetic license)
func on_black_hole_evaporated() -> void:
	entropy = maxf(entropy - 10.0, 0.0)
	EventBus.entropy_changed.emit(entropy)

# Living colonists (drives entropy rise and game over checks)
func _count_colonists() -> int:
	var n := 0
	for p in get_tree().get_nodes_in_group("colony_pawns"):
		if is_instance_valid(p) and p.faction == "colony" and not p.is_dead():
			n += 1
	return n
