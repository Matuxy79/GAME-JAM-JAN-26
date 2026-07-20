## BlackHole script. does game stuff in a simple way.
extends Node2D
class_name ColonyBlackHole

# A wandering micro black hole. Pulls pawns in, hurts whatever crosses the
# horizon, drains nearby resource nodes, then evaporates into harvestable
# Hawking shards. Straight out of chapter 7.

var radius: float = 26.0
var kill_radius: float = 18.0
var pull_radius: float = 120.0
var pull_strength: float = 55.0
var lifetime_ticks: int = 450
var shard_drops: int = 2
var damage_per_tick: float = 2.5

var _grid: ColonyGrid
var _director: EventDirector
var _age: int = 0
var _spin: float = 0.0

# Configure from the cosmology def
func setup(def: Dictionary, grid: ColonyGrid, director: EventDirector) -> void:
	radius = float(def.get("radius", 26.0))
	kill_radius = float(def.get("kill_radius", 18.0))
	pull_radius = float(def.get("pull_radius", 120.0))
	pull_strength = float(def.get("pull_strength", 55.0))
	lifetime_ticks = int(def.get("lifetime_ticks", 450))
	shard_drops = int(def.get("shard_drops", 2))
	damage_per_tick = float(def.get("damage_per_tick_in_kill_radius", 2.5))
	_grid = grid
	_director = director

func _ready():
	z_index = 5
	SimClock.sim_tick.connect(_on_sim_tick)

func _process(delta: float):
	_spin += delta * 2.0 * SimClock.get_speed_multiplier()
	queue_redraw()

# Pull, hurt, drain, age, evaporate
func _on_sim_tick(_tick: int) -> void:
	_age += 1
	for pawn in get_tree().get_nodes_in_group("colony_pawns"):
		if not is_instance_valid(pawn) or pawn.is_dead():
			continue
		var to_hole := position - pawn.position
		var dist := to_hole.length()
		if dist <= kill_radius + pawn.radius:
			pawn.take_damage(int(ceil(damage_per_tick)), position, 0.0, 2)
		elif dist <= pull_radius:
			# Stronger pull the closer you drift
			var strength := pull_strength * (1.0 - dist / pull_radius)
			pawn.position += to_hole.normalized() * strength * 0.1
	# Feed on nearby resource nodes
	for node in _grid.resource_nodes:
		if is_instance_valid(node) and not node.is_depleted():
			if position.distance_to(node.position) <= kill_radius:
				node.stock = 0.0
				node.queue_redraw()
	if _age >= lifetime_ticks:
		_evaporate()

# Hawking radiation: drop exotic shards, give some order back, vanish
func _evaporate() -> void:
	var node_script := load("res://src/scripts/colony/world/ResourceNode.gd")
	for _i in range(shard_drops):
		var shard: Node2D = node_script.new()
		shard.setup("hawking_shard")
		var offset := Vector2(randf_range(-40.0, 40.0), randf_range(-40.0, 40.0))
		shard.position = position + offset
		get_parent().add_child(shard)
		_grid.register_resource_node(shard)
	if _director != null:
		_director.on_black_hole_evaporated()
	EventBus.cosmology_event.emit("Black hole evaporated", position)
	queue_free()

# Event horizon, photon ring and a swirling accretion hint
func _draw():
	draw_circle(Vector2.ZERO, pull_radius, Color(0.3, 0.1, 0.5, 0.06))
	draw_circle(Vector2.ZERO, radius, Color(0.02, 0.02, 0.05))
	draw_arc(Vector2.ZERO, radius + 2.0, 0.0, TAU, 32, Color(1.0, 0.8, 0.4, 0.9), 2.0)
	draw_arc(Vector2.ZERO, radius + 8.0, _spin, _spin + TAU * 0.6, 24, Color(0.8, 0.5, 1.0, 0.4), 3.0)
