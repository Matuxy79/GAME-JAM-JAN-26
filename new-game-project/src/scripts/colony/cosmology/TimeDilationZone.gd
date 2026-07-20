## TimeDilationZone script. does game stuff in a simple way.
extends Node2D
class_name TimeDilationZone

# A gravity well where proper time runs slow. Pawns inside tick their needs,
# walking and work slower (Pawn checks the "time_zones" group every tick).

var radius: float = 96.0
var time_scale: float = 0.35
var lifetime_ticks: int = 600

var _age: int = 0
var _pulse: float = 0.0

# Configure from the cosmology def
func setup(def: Dictionary) -> void:
	radius = float(def.get("radius", 96.0))
	time_scale = float(def.get("time_scale", 0.35))
	lifetime_ticks = int(def.get("lifetime_ticks", 600))

func _ready():
	z_index = -2
	add_to_group("time_zones")
	SimClock.sim_tick.connect(_on_sim_tick)

func _process(delta: float):
	_pulse += delta * SimClock.get_speed_multiplier()
	queue_redraw()

# Age out eventually
func _on_sim_tick(_tick: int) -> void:
	_age += 1
	if _age >= lifetime_ticks:
		queue_free()

# Translucent purple well with a slow breathing ring
func _draw():
	draw_circle(Vector2.ZERO, radius, Color(0.55, 0.4, 0.85, 0.10))
	var ring := radius * (0.9 + 0.1 * sin(_pulse * 1.5))
	draw_arc(Vector2.ZERO, ring, 0.0, TAU, 40, Color(0.7, 0.55, 1.0, 0.45), 2.0)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 40, Color(0.7, 0.55, 1.0, 0.25), 1.0)
