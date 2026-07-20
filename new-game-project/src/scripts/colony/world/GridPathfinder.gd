## GridPathfinder script. does game stuff in a simple way.
extends RefCounted
class_name GridPathfinder

# Hand-rolled A* over a plain grid. No NavigationServer, no AStarGrid2D -
# just an open-list binary heap, octile heuristic, 8-way movement with no
# corner cutting. Scene-free so GUT can test it directly.

const ORTHO_COST := 1.0
const DIAG_COST := 1.41421

var width: int = 0
var height: int = 0
var _solid: Dictionary = {}

# Size the grid (all cells start walkable)
func setup(grid_width: int, grid_height: int) -> void:
	width = grid_width
	height = grid_height
	_solid = {}

# Block or unblock a cell
func set_solid(cell: Vector2i, solid: bool) -> void:
	if solid:
		_solid[cell] = true
	else:
		_solid.erase(cell)

# In bounds and not blocked
func is_walkable(cell: Vector2i) -> bool:
	if cell.x < 0 or cell.y < 0 or cell.x >= width or cell.y >= height:
		return false
	return not _solid.has(cell)

# A* from start to goal. Returns the cell path including both ends,
# or an empty array when unreachable.
func find_path(start: Vector2i, goal: Vector2i) -> Array[Vector2i]:
	var empty: Array[Vector2i] = []
	if not is_walkable(start) or not is_walkable(goal):
		return empty
	if start == goal:
		var trivial: Array[Vector2i] = [start]
		return trivial

	var open_heap: Array = []
	var g_score: Dictionary = {start: 0.0}
	var came_from: Dictionary = {}
	var closed: Dictionary = {}
	_heap_push(open_heap, [_heuristic(start, goal), start])

	while not open_heap.is_empty():
		var current: Vector2i = _heap_pop(open_heap)[1]
		if closed.has(current):
			continue
		if current == goal:
			return _reconstruct(came_from, current)
		closed[current] = true

		for neighbor_info in _neighbors(current):
			var neighbor: Vector2i = neighbor_info[0]
			var step_cost: float = neighbor_info[1]
			if closed.has(neighbor):
				continue
			var tentative: float = g_score[current] + step_cost
			if tentative < float(g_score.get(neighbor, INF)):
				g_score[neighbor] = tentative
				came_from[neighbor] = current
				_heap_push(open_heap, [tentative + _heuristic(neighbor, goal), neighbor])
	return empty

# Walkable neighbors with step costs. Diagonals only when both flanking
# orthogonal cells are free (no squeezing through corners).
func _neighbors(cell: Vector2i) -> Array:
	var out: Array = []
	for dir in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var next: Vector2i = cell + dir
		if is_walkable(next):
			out.append([next, ORTHO_COST])
	for dir in [Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)]:
		var next: Vector2i = cell + dir
		if is_walkable(next) and is_walkable(Vector2i(cell.x + dir.x, cell.y)) and is_walkable(Vector2i(cell.x, cell.y + dir.y)):
			out.append([next, DIAG_COST])
	return out

# Octile distance heuristic (admissible for 8-way grids)
func _heuristic(a: Vector2i, b: Vector2i) -> float:
	var dx := absf(float(a.x - b.x))
	var dy := absf(float(a.y - b.y))
	return ORTHO_COST * maxf(dx, dy) + (DIAG_COST - ORTHO_COST) * minf(dx, dy)

# Walk came_from back to the start
func _reconstruct(came_from: Dictionary, current: Vector2i) -> Array[Vector2i]:
	var path: Array[Vector2i] = [current]
	while came_from.has(current):
		current = came_from[current]
		path.push_front(current)
	return path

# --- tiny binary min-heap on [f, cell] entries ---

func _heap_push(heap: Array, entry: Array) -> void:
	heap.append(entry)
	var i := heap.size() - 1
	while i > 0:
		@warning_ignore("integer_division")
		var parent := (i - 1) / 2
		if heap[i][0] < heap[parent][0]:
			var tmp = heap[i]
			heap[i] = heap[parent]
			heap[parent] = tmp
			i = parent
		else:
			break

func _heap_pop(heap: Array) -> Array:
	var top: Array = heap[0]
	var last: Array = heap.pop_back()
	if not heap.is_empty():
		heap[0] = last
		var i := 0
		var size := heap.size()
		while true:
			var smallest := i
			var left := 2 * i + 1
			var right := 2 * i + 2
			if left < size and heap[left][0] < heap[smallest][0]:
				smallest = left
			if right < size and heap[right][0] < heap[smallest][0]:
				smallest = right
			if smallest == i:
				break
			var tmp = heap[i]
			heap[i] = heap[smallest]
			heap[smallest] = tmp
			i = smallest
	return top
