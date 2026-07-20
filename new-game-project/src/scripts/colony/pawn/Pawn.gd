## Pawn script. does game stuff in a simple way.
extends Node2D
class_name ColonyPawn

# A colonist (or raider). Finite state machine driven by sim ticks:
# IDLE -> needs first (eat/sleep), then jobs from the JobManager, and COMBAT
# interrupts everything when hostiles get close. Movement runs in _process so
# pawns glide smoothly between ticks. Time dilation zones slow a pawn's whole
# life down via time_scale. Stats come from a "pawns" def - see MODDING.md.

enum State { IDLE, MOVE_TO, WORK, EAT, SLEEP, COMBAT, DEAD }

const STATE_NAMES := ["Idle", "Moving", "Working", "Eating", "Sleeping", "Fighting", "Dead"]
const COMBAT_ALERT_RANGE := 180.0
const CORPSE_FADE_TICKS := 80

var def_id: String = ""
var pawn_name: String = "Pawn"
var faction: String = "colony"
var max_health: int = 100
var health: int = 100
var move_speed: float = 80.0
var body_color := Color.WHITE
var radius: float = 10.0
var needs := PawnNeeds.new()
var harvest_ticks: int = 20
var selected: bool = false

var grid: ColonyGrid
var jobs: JobManager
var resources: ColonyResources
var ability_runner: AbilityRunner

var state: int = State.IDLE
var _path := PackedVector2Array()
var _path_index: int = 0
var _purpose: String = ""
var _job: Dictionary = {}
var _work_progress: int = 0
var _carrying: Dictionary = {}
var _facing := Vector2.RIGHT
var _hitstun_ticks: int = 0
var _knockback := Vector2.ZERO
var _time_scale: float = 1.0
var _corpse_ticks: int = 0
var _idle_cooldown: int = 0

# Configure from a pawn def and wire world refs (call before add_child)
func setup(id: String, colony_grid: ColonyGrid, job_manager: JobManager, colony_resources: ColonyResources, display_name: String = "") -> void:
	def_id = id
	grid = colony_grid
	jobs = job_manager
	resources = colony_resources
	var def: Dictionary = DefDatabase.get_def("pawns", id)
	if def.is_empty():
		push_error("Pawn: unknown pawn def: " + id)
		return
	pawn_name = display_name if display_name != "" else str(def.get("name", id))
	faction = str(def.get("faction", "colony"))
	max_health = int(def.get("max_health", 100))
	health = max_health
	move_speed = float(def.get("move_speed", 80.0))
	body_color = Color(def.get("color", "#ffffff"))
	radius = float(def.get("radius", 10.0))
	needs.configure(def.get("needs", {}))
	harvest_ticks = int(def.get("work", {}).get("harvest_ticks", 20))
	ability_runner = AbilityRunner.new()
	ability_runner.setup(self, def.get("abilities", []))
	add_child(ability_runner)

func _ready():
	add_to_group("colony_pawns")
	SimClock.sim_tick.connect(_on_sim_tick)
	queue_redraw()

# True when dead (combat targeting skips corpses)
func is_dead() -> bool:
	return state == State.DEAD

# Human-readable state for the HUD inspector
func get_state_name() -> String:
	return STATE_NAMES[state]

# Take a hit: damage, knockback, hitstun, cancel current attack, flash white
func take_damage(amount: int, source_pos: Vector2, knockback: float, hitstun_ticks: int) -> void:
	if is_dead():
		return
	health -= amount
	_hitstun_ticks = maxi(_hitstun_ticks, hitstun_ticks)
	var away := (position - source_pos).normalized()
	if away == Vector2.ZERO:
		away = Vector2.RIGHT
	_knockback = away * knockback
	if ability_runner:
		ability_runner.interrupt()
	# Impact flash
	modulate = Color(3.0, 3.0, 3.0)
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.18)
	if health <= 0:
		_die()
	queue_redraw()

# Smooth movement, knockback and facing run every frame
func _process(delta: float):
	if is_dead():
		return
	var sim_mult := SimClock.get_speed_multiplier()
	# Knockback ignores hitstun (that's the point of getting launched)
	if _knockback.length() > 1.0:
		position += _knockback * delta * sim_mult
		_knockback = _knockback.move_toward(Vector2.ZERO, 600.0 * delta * sim_mult)
	if _hitstun_ticks > 0 or sim_mult <= 0.0:
		return
	if state == State.MOVE_TO:
		_advance_path(delta * sim_mult * _time_scale)

# One sim tick of pawn brain
func _on_sim_tick(tick: int) -> void:
	if is_dead():
		_corpse_ticks += 1
		if _corpse_ticks > CORPSE_FADE_TICKS:
			queue_free()
		return

	_time_scale = _compute_time_scale()

	# Needs always tick (starvation damage comes back)
	var starve_damage := needs.tick(_time_scale)
	if starve_damage > 0.0 and tick % 4 == 0:
		take_damage(int(ceil(starve_damage * 4.0)), position, 0.0, 0)
		if is_dead():
			return

	if _hitstun_ticks > 0:
		_hitstun_ticks -= 1
		return

	ability_runner.tick()

	# Hostiles nearby trump everything except sleeping off exhaustion at 0
	if state != State.COMBAT and _find_enemy(COMBAT_ALERT_RANGE) != null:
		_abandon_job()
		state = State.COMBAT

	match state:
		State.IDLE:
			_tick_idle()
		State.WORK:
			_tick_work()
		State.EAT:
			_tick_eat()
		State.SLEEP:
			_tick_sleep()
		State.COMBAT:
			_tick_combat()
		State.MOVE_TO:
			pass # movement itself runs in _process
	queue_redraw()

# --- state ticks ---

# Pick what to do next: needs first, then work, then wander
func _tick_idle() -> void:
	# Raiders don't harvest berries; they only ever hunt
	if faction != "colony":
		state = State.COMBAT
		return
	if _idle_cooldown > 0:
		_idle_cooldown -= 1
		return
	if needs.is_hungry():
		if resources != null and resources.get_amount("food") > 0:
			_go_to(grid.stockpile_pos(), "eat")
			return
		var bush := grid.find_resource_node("food", position)
		if bush != null:
			_go_to(bush.position, "graze", {"node": bush})
			return
	if needs.is_exhausted():
		_go_to(grid.camp_pos(), "sleep")
		return
	if jobs != null:
		var job := jobs.request_job(self)
		if not job.is_empty():
			_job = job
			_go_to(job["node"].position, "work")
			return
	# Nothing to do: wander somewhere close
	var wander := grid.cell_to_world(grid.random_walkable_cell())
	if position.distance_to(wander) < 400.0:
		_go_to(wander, "idle")
	_idle_cooldown = 10

# Chip away at the resource node, then haul the goods home
func _tick_work() -> void:
	var node: Node2D = _job.get("node")
	if node == null or not is_instance_valid(node) or node.is_depleted():
		_abandon_job()
		state = State.IDLE
		return
	_work_progress += 1
	if _work_progress >= harvest_ticks:
		var got: int = node.harvest()
		if got > 0:
			_carrying[node.yields] = int(_carrying.get(node.yields, 0)) + got
		jobs.release_claim(node)
		_job = {}
		_go_to(grid.stockpile_pos(), "deposit")

# Chow down at the stockpile (or straight off the bush when grazing)
func _tick_eat() -> void:
	if resources != null and resources.take("food", 1):
		needs.eat()
	state = State.IDLE

# Sleep until rested (or until hunger gets desperate)
func _tick_sleep() -> void:
	needs.sleep_tick(_time_scale)
	if needs.is_rested() or (needs.is_hungry() and needs.hunger <= 5.0):
		state = State.IDLE

# Chase the nearest enemy and swing when in reach
func _tick_combat() -> void:
	var enemy := _find_enemy(INF if faction == "raider" else COMBAT_ALERT_RANGE * 1.6)
	if enemy == null:
		state = State.IDLE
		return
	_facing = (enemy.position - position).normalized()
	var reach := ability_runner.get_attack_range()
	var dist := position.distance_to(enemy.position)
	if dist <= reach + enemy.radius:
		if not ability_runner.is_busy():
			ability_runner.try_attack(enemy.position, SimClock.tick)
	elif not ability_runner.is_busy():
		# Step toward the enemy (simple straight chase, pathfind if blocked)
		var step := _facing * move_speed * 0.1 * _time_scale
		var next_cell := grid.world_to_cell(position + step * 3.0)
		if grid.is_walkable(next_cell):
			position += step
		else:
			_go_to(enemy.position, "combat")

# --- helpers ---

# Path somewhere, then switch to the state matching the purpose
func _go_to(target: Vector2, purpose: String, context: Dictionary = {}) -> void:
	_path = grid.find_path(position, target)
	if _path.is_empty():
		_abandon_job()
		state = State.IDLE
		_idle_cooldown = 10
		return
	_path_index = 0
	_purpose = purpose
	if context.has("node"):
		_job = {"type": "graze", "node": context["node"]}
	state = State.MOVE_TO

# Walk the current path; arriving flips to the purpose state
func _advance_path(scaled_delta: float) -> void:
	if _path_index >= _path.size():
		_arrive()
		return
	var target: Vector2 = _path[_path_index]
	var step := move_speed * scaled_delta
	if position.distance_to(target) <= step:
		position = target
		_path_index += 1
		if _path_index >= _path.size():
			_arrive()
	else:
		var dir := (target - position).normalized()
		_facing = dir
		position += dir * step

# We got where we were going; act on why we went
func _arrive() -> void:
	_path = PackedVector2Array()
	match _purpose:
		"work":
			_work_progress = 0
			state = State.WORK
		"eat":
			state = State.EAT
		"graze":
			var node: Node2D = _job.get("node")
			if node != null and is_instance_valid(node) and not node.is_depleted():
				if node.harvest() > 0:
					needs.eat()
			_job = {}
			state = State.IDLE
		"sleep":
			state = State.SLEEP
		"deposit":
			for kind in _carrying.keys():
				resources.add(kind, int(_carrying[kind]))
			_carrying = {}
			state = State.IDLE
		"combat":
			state = State.COMBAT
		_:
			state = State.IDLE
	_purpose = ""

# Drop the current job claim if we have one
func _abandon_job() -> void:
	var node: Node2D = _job.get("node")
	if node != null and jobs != null:
		jobs.release_claim(node)
	_job = {}
	_work_progress = 0

# Nearest living pawn of another faction within range (null if none)
func _find_enemy(within: float) -> Node2D:
	var best: Node2D = null
	var best_dist := within * within
	for other in get_tree().get_nodes_in_group("colony_pawns"):
		if other == self or not is_instance_valid(other):
			continue
		if other.faction == faction or other.is_dead():
			continue
		var d: float = position.distance_squared_to(other.position)
		if d < best_dist:
			best_dist = d
			best = other
	return best

# Slowest time dilation zone we are standing in (1.0 = normal spacetime)
func _compute_time_scale() -> float:
	var slowest := 1.0
	for zone in get_tree().get_nodes_in_group("time_zones"):
		if not is_instance_valid(zone):
			continue
		if position.distance_to(zone.position) <= zone.radius:
			slowest = minf(slowest, zone.time_scale)
	return slowest

# Flop over and tell the world
func _die() -> void:
	state = State.DEAD
	_abandon_job()
	_knockback = Vector2.ZERO
	modulate = Color(0.45, 0.45, 0.45, 0.9)
	EventBus.pawn_died.emit(self)
	queue_redraw()

# Draw the pawn: body, facing tick, health bar, selection ring, sleep dim
func _draw():
	var c := body_color
	if state == State.SLEEP:
		c = c.darkened(0.4)
	draw_circle(Vector2.ZERO, radius, c)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 24, Color(0, 0, 0, 0.6), 1.5)
	if not is_dead():
		draw_line(Vector2.ZERO, _facing * (radius + 4.0), Color(1, 1, 1, 0.8), 2.0)
	if selected:
		draw_arc(Vector2.ZERO, radius + 5.0, 0.0, TAU, 24, Color(1, 1, 0.4, 0.9), 2.0)
	if health < max_health and not is_dead():
		var w := radius * 2.0
		var frac := float(health) / float(max_health)
		draw_rect(Rect2(-radius, -radius - 8.0, w, 3.0), Color(0, 0, 0, 0.6))
		draw_rect(Rect2(-radius, -radius - 8.0, w * frac, 3.0), Color(0.9, 0.25, 0.25))
	if _time_scale < 1.0 and not is_dead():
		draw_arc(Vector2.ZERO, radius + 8.0, 0.0, TAU, 24, Color(0.79, 0.64, 1.0, 0.5), 1.5)
