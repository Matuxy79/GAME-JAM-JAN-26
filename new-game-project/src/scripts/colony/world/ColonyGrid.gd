## ColonyGrid script. does game stuff in a simple way.
extends Node2D
class_name ColonyGrid

# The colony map. Owns the tile grid, water, pathfinding, resource nodes,
# the stockpile and the camp (sleep spot). Drawn with plain rects so no
# tileset assets are needed - drop real tiles in later without touching logic.

const CELL := 32
const GRID_W := 40
const GRID_H := 26

const COLOR_GRASS := Color("#3f5e3b")
const COLOR_GRASS_ALT := Color("#446540")
const COLOR_WATER := Color("#2b4a6f")
const COLOR_STOCKPILE := Color("#6b5d33")
const COLOR_CAMP := Color("#54466b")

var astar := AStarGrid2D.new()
var water_cells: Dictionary = {}
var stockpile_cell := Vector2i(GRID_W / 2, GRID_H / 2)
var camp_cell := Vector2i(GRID_W / 2 - 3, GRID_H / 2)
var resource_nodes: Array = []

var _rng := RandomNumberGenerator.new()

func _ready():
	_rng.seed = 1337
	_generate_terrain()
	_setup_astar()
	_spawn_resource_nodes()
	queue_redraw()

# Grid cell -> world position (cell center)
func cell_to_world(cell: Vector2i) -> Vector2:
	return Vector2(cell.x * CELL + CELL / 2.0, cell.y * CELL + CELL / 2.0)

# World position -> grid cell
func world_to_cell(pos: Vector2) -> Vector2i:
	return Vector2i(int(pos.x / CELL), int(pos.y / CELL))

# True if a cell is inside the map and not water
func is_walkable(cell: Vector2i) -> bool:
	if cell.x < 0 or cell.y < 0 or cell.x >= GRID_W or cell.y >= GRID_H:
		return false
	return not water_cells.has(cell)

# Path between world points (list of world positions, empty if blocked)
func find_path(from_pos: Vector2, to_pos: Vector2) -> PackedVector2Array:
	var from_cell := world_to_cell(from_pos)
	var to_cell := world_to_cell(to_pos)
	if not is_walkable(from_cell) or not is_walkable(to_cell):
		return PackedVector2Array()
	var cells := astar.get_id_path(from_cell, to_cell)
	var out := PackedVector2Array()
	for c in cells:
		out.append(cell_to_world(c))
	return out

# A random walkable cell (for spawns and idle wandering)
func random_walkable_cell() -> Vector2i:
	for _i in range(200):
		var cell := Vector2i(_rng.randi_range(0, GRID_W - 1), _rng.randi_range(0, GRID_H - 1))
		if is_walkable(cell):
			return cell
	return stockpile_cell

# A walkable cell on the map edge (raids come from here)
func random_edge_cell() -> Vector2i:
	for _i in range(200):
		var cell: Vector2i
		match _rng.randi_range(0, 3):
			0: cell = Vector2i(_rng.randi_range(0, GRID_W - 1), 0)
			1: cell = Vector2i(_rng.randi_range(0, GRID_W - 1), GRID_H - 1)
			2: cell = Vector2i(0, _rng.randi_range(0, GRID_H - 1))
			_: cell = Vector2i(GRID_W - 1, _rng.randi_range(0, GRID_H - 1))
		if is_walkable(cell):
			return cell
	return Vector2i(0, 0)

# World-space center of the map (camera start)
func map_center() -> Vector2:
	return Vector2(GRID_W * CELL / 2.0, GRID_H * CELL / 2.0)

# World-space stockpile position (haul target)
func stockpile_pos() -> Vector2:
	return cell_to_world(stockpile_cell)

# World-space camp position (sleep target)
func camp_pos() -> Vector2:
	return cell_to_world(camp_cell)

# Register a resource node so jobs can find it
func register_resource_node(node: Node2D) -> void:
	resource_nodes.append(node)

# Closest live resource node yielding a given resource ("food"/"wood")
func find_resource_node(yields: String, near_pos: Vector2) -> Node2D:
	var best: Node2D = null
	var best_dist := INF
	for node in resource_nodes:
		if not is_instance_valid(node) or node.is_depleted() or node.yields != yields:
			continue
		var d: float = near_pos.distance_squared_to(node.position)
		if d < best_dist:
			best_dist = d
			best = node
	return best

# Carve some water blobs so pathfinding has something to route around
func _generate_terrain() -> void:
	for _blob in range(5):
		var cx := _rng.randi_range(4, GRID_W - 5)
		var cy := _rng.randi_range(3, GRID_H - 4)
		var r := _rng.randi_range(1, 3)
		for x in range(cx - r, cx + r + 1):
			for y in range(cy - r, cy + r + 1):
				var cell := Vector2i(x, y)
				if Vector2(cell - Vector2i(cx, cy)).length() <= float(r):
					if cell != stockpile_cell and cell != camp_cell:
						water_cells[cell] = true

# Configure AStarGrid2D over the map
func _setup_astar() -> void:
	astar.region = Rect2i(0, 0, GRID_W, GRID_H)
	astar.cell_size = Vector2(CELL, CELL)
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	astar.update()
	for cell in water_cells.keys():
		astar.set_point_solid(cell, true)

# Sprinkle berry bushes and trees around the map
func _spawn_resource_nodes() -> void:
	var node_script := load("res://src/scripts/colony/world/ResourceNode.gd")
	var wanted := {"berry_bush": 8, "tree": 10}
	for def_id in wanted.keys():
		for _i in range(wanted[def_id]):
			var cell := random_walkable_cell()
			if cell == stockpile_cell or cell == camp_cell:
				continue
			var node: Node2D = node_script.new()
			node.setup(def_id)
			node.position = cell_to_world(cell)
			add_child(node)
			register_resource_node(node)

# Draw the ground, water, stockpile and camp
func _draw():
	for x in range(GRID_W):
		for y in range(GRID_H):
			var cell := Vector2i(x, y)
			var rect := Rect2(x * CELL, y * CELL, CELL, CELL)
			var color := COLOR_GRASS if (x + y) % 2 == 0 else COLOR_GRASS_ALT
			if water_cells.has(cell):
				color = COLOR_WATER
			elif cell == stockpile_cell:
				color = COLOR_STOCKPILE
			elif cell == camp_cell:
				color = COLOR_CAMP
			draw_rect(rect, color)
	# Border so the map edge reads clearly
	draw_rect(Rect2(0, 0, GRID_W * CELL, GRID_H * CELL), Color(0, 0, 0, 0.85), false, 2.0)
