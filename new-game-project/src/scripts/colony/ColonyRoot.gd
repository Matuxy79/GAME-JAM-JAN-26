## ColonyRoot script. does game stuff in a simple way.
extends Node2D
class_name ColonyRoot

# Colony mode entry point. Builds the world, spawns the starting colonists,
# runs camera + selection input, and watches for the colony wipe. Everything
# is assembled in code so the .tscn stays a one-node stub.

const START_MENU_SCENE := "res://src/scenes/UI/StartMenu.tscn"
const STARTING_COLONISTS := ["Ada", "Kip", "Rook"]

var grid: ColonyGrid
var resources := ColonyResources.new()
var jobs: JobManager
var director: EventDirector
var pawn_container: Node2D
var hud: ColonyHUD
var camera: Camera2D

var selected_pawn: Node2D = null
var _game_over := false
var _dragging := false

func _ready():
	print("ColonyRoot initialized")
	grid = ColonyGrid.new()
	add_child(grid)

	jobs = JobManager.new()
	jobs.setup(grid, resources)
	add_child(jobs)

	pawn_container = Node2D.new()
	pawn_container.name = "Pawns"
	add_child(pawn_container)

	director = EventDirector.new()
	director.setup(grid, pawn_container)
	add_child(director)

	camera = Camera2D.new()
	camera.position = grid.map_center()
	camera.zoom = Vector2(0.9, 0.9)
	add_child(camera)
	camera.make_current()

	hud = ColonyHUD.new()
	add_child(hud)

	EventBus.pawn_died.connect(_on_pawn_died)

	for colonist_name in STARTING_COLONISTS:
		var pos := grid.camp_pos() + Vector2(randf_range(-40.0, 40.0), randf_range(-40.0, 40.0))
		spawn_pawn("colonist", pos, colonist_name)

	SimClock.start()
	EventBus.colony_resources_changed.emit(resources.amounts)

func _exit_tree():
	SimClock.stop()

# Spawn any pawn def at a position (EventDirector uses this for raids)
func spawn_pawn(def_id: String, pos: Vector2, display_name: String = "") -> Node2D:
	var pawn := ColonyPawn.new()
	pawn.setup(def_id, grid, jobs, resources, display_name)
	pawn.position = pos
	pawn_container.add_child(pawn)
	return pawn

# Camera + selection input
func _unhandled_input(event):
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				if event.pressed:
					_select_at(get_global_mouse_position())
			MOUSE_BUTTON_WHEEL_UP:
				if event.pressed:
					camera.zoom = (camera.zoom * 1.1).clamp(Vector2(0.4, 0.4), Vector2(2.5, 2.5))
			MOUSE_BUTTON_WHEEL_DOWN:
				if event.pressed:
					camera.zoom = (camera.zoom / 1.1).clamp(Vector2(0.4, 0.4), Vector2(2.5, 2.5))
			MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE:
				_dragging = event.pressed
	elif event is InputEventMouseMotion and _dragging:
		camera.position -= event.relative / camera.zoom.x
	elif event is InputEventScreenDrag:
		# One-finger drag pans on touch
		camera.position -= event.relative / camera.zoom.x
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_SPACE:
				SimClock.set_speed(0 if SimClock.speed_index != 0 else 1)
			KEY_1:
				SimClock.set_speed(1)
			KEY_2:
				SimClock.set_speed(2)
			KEY_3:
				SimClock.set_speed(3)
			KEY_ESCAPE:
				SimClock.stop()
				get_tree().change_scene_to_file(START_MENU_SCENE)

# Click a pawn (or empty ground to clear)
func _select_at(pos: Vector2) -> void:
	var best: Node2D = null
	var best_dist := 24.0 * 24.0
	for pawn in get_tree().get_nodes_in_group("colony_pawns"):
		if not is_instance_valid(pawn) or pawn.is_dead():
			continue
		var d: float = pos.distance_squared_to(pawn.position)
		if d < best_dist:
			best_dist = d
			best = pawn
	if selected_pawn != null and is_instance_valid(selected_pawn):
		selected_pawn.selected = false
		selected_pawn.queue_redraw()
	selected_pawn = best
	if best != null:
		best.selected = true
		best.queue_redraw()
	EventBus.colonist_selected.emit(best)

# Wipe check: no living colonists means entropy wins
func _on_pawn_died(pawn: Node2D) -> void:
	if _game_over or pawn.faction != "colony":
		return
	for p in get_tree().get_nodes_in_group("colony_pawns"):
		if is_instance_valid(p) and p.faction == "colony" and not p.is_dead():
			return
	_game_over = true
	SimClock.set_speed(0)
	EventBus.colony_game_over.emit(SimClock.get_day())
