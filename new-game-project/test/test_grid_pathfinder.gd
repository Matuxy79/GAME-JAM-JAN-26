extends GutTest

# Test suite for the hand-rolled A* GridPathfinder
# Covers straight paths, detours, corner cutting and unreachable goals

var finder: GridPathfinder

func before_each():
	finder = GridPathfinder.new()
	finder.setup(10, 10)

func test_straight_path():
	"""A clear straight line should path directly"""
	var path = finder.find_path(Vector2i(0, 0), Vector2i(4, 0))
	assert_eq(path.size(), 5, "Straight path should visit 5 cells")
	assert_eq(path[0], Vector2i(0, 0), "Path should start at the start")
	assert_eq(path[4], Vector2i(4, 0), "Path should end at the goal")

func test_same_cell():
	"""Start == goal should return just that cell"""
	var path = finder.find_path(Vector2i(3, 3), Vector2i(3, 3))
	assert_eq(path.size(), 1, "Trivial path should be one cell")

func test_detour_around_wall():
	"""A wall between start and goal forces a longer path"""
	for y in range(0, 9):
		finder.set_solid(Vector2i(5, y), true)
	var path = finder.find_path(Vector2i(0, 0), Vector2i(9, 0))
	assert_gt(path.size(), 10, "Detour should be longer than the direct line")
	for cell in path:
		assert_true(finder.is_walkable(cell), "Path must avoid solid cells")

func test_unreachable_goal():
	"""A fully enclosed goal should return an empty path"""
	for offset in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)]:
		finder.set_solid(Vector2i(8, 8) + offset, true)
	var path = finder.find_path(Vector2i(0, 0), Vector2i(8, 8))
	assert_eq(path.size(), 0, "Enclosed goal should be unreachable")

func test_no_corner_cutting():
	"""Diagonals must not squeeze between two solid cells"""
	finder.set_solid(Vector2i(1, 0), true)
	finder.set_solid(Vector2i(0, 1), true)
	var path = finder.find_path(Vector2i(0, 0), Vector2i(2, 2))
	assert_eq(path.size(), 0, "Corner-cut diagonal should be blocked (0,0 is sealed)")

func test_solid_start_or_goal():
	"""Solid endpoints should fail fast"""
	finder.set_solid(Vector2i(0, 0), true)
	assert_eq(finder.find_path(Vector2i(0, 0), Vector2i(5, 5)).size(), 0, "Solid start has no path")
	assert_eq(finder.find_path(Vector2i(5, 5), Vector2i(0, 0)).size(), 0, "Solid goal has no path")

func test_out_of_bounds():
	"""Cells outside the grid are not walkable"""
	assert_false(finder.is_walkable(Vector2i(-1, 0)), "Negative x is out of bounds")
	assert_false(finder.is_walkable(Vector2i(0, 10)), "y == height is out of bounds")
