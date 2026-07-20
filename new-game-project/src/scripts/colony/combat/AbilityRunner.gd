## AbilityRunner script. does game stuff in a simple way.
extends Node2D
class_name AbilityRunner

# CombatAbility executor with FGC frame data. Every ability def declares
# startup / active / recovery ticks, damage, arc, knockback, hitstun and
# hit-stop. The runner steps through those phases on sim ticks, hits
# everything in the arc during active frames, and layers on the anime juice
# (hit-stop, afterimages, swing flash). Abilities are pure JSON defs, so
# mods can add new moves without touching this file. See MODDING.md.

enum Phase { READY, STARTUP, ACTIVE, RECOVERY }

static var _hit_stop_active := false

var pawn: Node2D
var ability_ids: Array = []

var phase: int = Phase.READY
var _phase_ticks_left: int = 0
var _current: Dictionary = {}
var _current_id: String = ""
var _aim_dir := Vector2.RIGHT
var _cooldowns: Dictionary = {}
var _already_hit: Dictionary = {}

# Wire to the owning pawn and its ability list
func setup(owner_pawn: Node2D, ids: Array) -> void:
	pawn = owner_pawn
	ability_ids = ids

# True while mid-move (can't start another)
func is_busy() -> bool:
	return phase != Phase.READY

# Getting hit cancels whatever we were doing (FGC rules)
func interrupt() -> void:
	phase = Phase.READY
	_current = {}
	_current_id = ""
	queue_redraw()

# Try to start the first off-cooldown ability toward a target. True if started.
func try_attack(target_pos: Vector2, current_tick: int) -> bool:
	if is_busy():
		return false
	for id in ability_ids:
		if int(_cooldowns.get(id, 0)) > current_tick:
			continue
		var def: Dictionary = DefDatabase.get_def("abilities", id)
		if def.is_empty():
			push_error("AbilityRunner: unknown ability def: " + str(id))
			continue
		_current = def
		_current_id = id
		_aim_dir = (target_pos - pawn.position).normalized()
		if _aim_dir == Vector2.ZERO:
			_aim_dir = Vector2.RIGHT
		phase = Phase.STARTUP
		_phase_ticks_left = int(def.get("startup_ticks", 1))
		_already_hit = {}
		_cooldowns[id] = current_tick + int(def.get("cooldown_ticks", 10))
		queue_redraw()
		return true
	return false

# Reach of the first ability (AI uses this to know when it's close enough)
func get_attack_range() -> float:
	if ability_ids.is_empty():
		return 30.0
	var def: Dictionary = DefDatabase.get_def("abilities", ability_ids[0])
	return float(def.get("range", 30.0))

# Advance the frame-data phases; pawn calls this every sim tick
func tick() -> void:
	if phase == Phase.READY:
		return
	_phase_ticks_left -= 1
	if phase == Phase.ACTIVE:
		_apply_active_hits()
		if bool(_current.get("afterimage", false)):
			_spawn_afterimage()
	if _phase_ticks_left > 0:
		queue_redraw()
		return
	match phase:
		Phase.STARTUP:
			phase = Phase.ACTIVE
			_phase_ticks_left = int(_current.get("active_ticks", 1))
		Phase.ACTIVE:
			phase = Phase.RECOVERY
			_phase_ticks_left = int(_current.get("recovery_ticks", 1))
		Phase.RECOVERY:
			phase = Phase.READY
			_current = {}
			_current_id = ""
	queue_redraw()

# Damage everything hostile inside the active arc (once per swing)
func _apply_active_hits() -> void:
	var reach := float(_current.get("range", 30.0))
	var half_arc := deg_to_rad(float(_current.get("arc_degrees", 90.0)) / 2.0)
	for other in get_tree().get_nodes_in_group("colony_pawns"):
		if other == pawn or not is_instance_valid(other):
			continue
		if other.faction == pawn.faction or other.is_dead():
			continue
		if _already_hit.has(other.get_instance_id()):
			continue
		var to_other: Vector2 = other.position - pawn.position
		if to_other.length() > reach + other.radius:
			continue
		if absf(_aim_dir.angle_to(to_other.normalized())) > half_arc:
			continue
		_already_hit[other.get_instance_id()] = true
		other.take_damage(
			int(_current.get("damage", 5)),
			pawn.position,
			float(_current.get("knockback", 0.0)),
			int(_current.get("hitstun_ticks", 0)))
		_do_hit_stop(float(_current.get("hit_stop_seconds", 0.0)))

# Freeze the whole game for a few real milliseconds on impact
func _do_hit_stop(seconds: float) -> void:
	if seconds <= 0.0 or _hit_stop_active:
		return
	_hit_stop_active = true
	var previous := Engine.time_scale
	Engine.time_scale = 0.05
	# Timer ignores time_scale so the freeze actually ends
	await get_tree().create_timer(seconds, true, false, true).timeout
	Engine.time_scale = previous
	_hit_stop_active = false

# Ghost trail behind the attacker during active frames
func _spawn_afterimage() -> void:
	var ghost := AfterimageGhost.new()
	ghost.color = pawn.body_color
	ghost.radius = pawn.radius
	ghost.position = pawn.position
	pawn.get_parent().add_child(ghost)

# Draw the swing wedge during startup (wind-up, dim) and active (bright)
func _draw():
	if phase != Phase.STARTUP and phase != Phase.ACTIVE:
		return
	if _current.is_empty():
		return
	var reach := float(_current.get("range", 30.0))
	var half_arc := deg_to_rad(float(_current.get("arc_degrees", 90.0)) / 2.0)
	var color := Color(_current.get("swing_color", "#ffffff"))
	color.a = 0.85 if phase == Phase.ACTIVE else 0.25
	var base_angle := _aim_dir.angle()
	var points := PackedVector2Array([Vector2.ZERO])
	for i in range(13):
		var angle := base_angle - half_arc + (half_arc * 2.0) * (float(i) / 12.0)
		points.append(Vector2(cos(angle), sin(angle)) * reach)
	draw_colored_polygon(points, color)


# Little fading ghost circle left behind by anime-flavored moves
class AfterimageGhost extends Node2D:
	var color := Color.WHITE
	var radius := 10.0
	var _life := 0.25

	func _ready():
		z_index = -1

	func _process(delta: float):
		_life -= delta
		if _life <= 0.0:
			queue_free()
			return
		queue_redraw()

	func _draw():
		var c := color
		c.a = 0.4 * (_life / 0.25)
		draw_circle(Vector2.ZERO, radius, c)
