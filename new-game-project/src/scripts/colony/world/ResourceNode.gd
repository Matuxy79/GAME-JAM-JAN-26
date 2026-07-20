## ResourceNode script. does game stuff in a simple way.
extends Node2D
class_name ColonyResourceNode

# A harvestable thing on the map (berry bush, tree, hawking shard...).
# Driven by a "resources" def from DefDatabase. Regrows slowly on sim ticks.

var def_id: String = ""
var yields: String = ""
var yield_amount: int = 0
var max_stock: float = 0.0
var regrow_per_tick: float = 0.0
var stock: float = 0.0
var color := Color.WHITE

# Configure from a def id (call before add_child)
func setup(id: String) -> void:
	def_id = id
	var def: Dictionary = DefDatabase.get_def("resources", id)
	if def.is_empty():
		push_error("ResourceNode: unknown resource def: " + id)
		return
	yields = def.get("yields", "")
	yield_amount = int(def.get("yield_amount", 1))
	max_stock = float(def.get("max_stock", 10))
	regrow_per_tick = float(def.get("regrow_per_tick", 0.0))
	stock = max_stock
	color = Color(def.get("color", "#ffffff"))

func _ready():
	SimClock.sim_tick.connect(_on_sim_tick)
	queue_redraw()

# Regrow a little every tick
func _on_sim_tick(_tick: int) -> void:
	if regrow_per_tick > 0.0 and stock < max_stock:
		stock = minf(stock + regrow_per_tick, max_stock)
		queue_redraw()

# True when there is nothing left to take
func is_depleted() -> bool:
	return stock < float(yield_amount)

# Take one harvest worth of stuff (returns amount actually taken)
func harvest() -> int:
	if is_depleted():
		return 0
	stock -= float(yield_amount)
	queue_redraw()
	return yield_amount

# Draw a blob sized by remaining stock
func _draw():
	var fullness := 0.0
	if max_stock > 0.0:
		fullness = clampf(stock / max_stock, 0.0, 1.0)
	var radius := 6.0 + 6.0 * fullness
	draw_circle(Vector2.ZERO, radius, color)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 20, Color(0, 0, 0, 0.5), 1.5)
