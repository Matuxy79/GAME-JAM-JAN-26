## JobManager script. does game stuff in a simple way.
extends Node
class_name JobManager

# Hands out work to idle colonists. Keeps it dumb on purpose: food first when
# the pantry runs low, otherwise alternate food and wood harvesting. Nodes get
# claimed so two pawns never fight over the same bush.

const LOW_FOOD := 6

var grid: ColonyGrid
var resources: ColonyResources

# instance_id -> true for resource nodes someone already claimed
var _claims: Dictionary = {}
var _flip := false

# Wire up world refs (ColonyRoot calls this)
func setup(colony_grid: ColonyGrid, colony_resources: ColonyResources) -> void:
	grid = colony_grid
	resources = colony_resources

# Ask for work. Returns {type, node} or {} when nothing to do.
func request_job(pawn: Node2D) -> Dictionary:
	var wanted: Array[String] = []
	if resources.get_amount("food") < LOW_FOOD:
		wanted = ["food", "wood"]
	else:
		_flip = not _flip
		wanted = ["food", "wood"] if _flip else ["wood", "food"]
	for yields in wanted:
		var node := _find_unclaimed(yields, pawn.position)
		if node != null:
			_claims[node.get_instance_id()] = true
			return {"type": "harvest", "node": node}
	return {}

# Give a claim back (job done or abandoned)
func release_claim(node: Node2D) -> void:
	if is_instance_valid(node):
		_claims.erase(node.get_instance_id())

# Nearest live unclaimed node yielding what we want
func _find_unclaimed(yields: String, near_pos: Vector2) -> Node2D:
	var best: Node2D = null
	var best_dist := INF
	for node in grid.resource_nodes:
		if not is_instance_valid(node) or node.is_depleted() or node.yields != yields:
			continue
		if _claims.has(node.get_instance_id()):
			continue
		var d: float = near_pos.distance_squared_to(node.position)
		if d < best_dist:
			best_dist = d
			best = node
	return best
