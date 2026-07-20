## Pawn script. base colonist pawn with lightweight wandering behavior.
extends CharacterBody2D
class_name Pawn

@export var pawn_name: String = "Colonist"
@export var move_speed: float = 36.0
@export var wander_radius: float = 80.0
@export var retarget_interval: float = 2.5

var _origin: Vector2
var _target_position: Vector2
var _retarget_timer: float = 0.0

func _ready():
	add_to_group("pawn")
	_origin = global_position
	_pick_next_target()

func _physics_process(delta: float):
	_retarget_timer -= delta
	if _retarget_timer <= 0.0 or global_position.distance_to(_target_position) < 8.0:
		_pick_next_target()

	var direction := (_target_position - global_position).normalized()
	velocity = direction * move_speed
	move_and_slide()

func _pick_next_target():
	_retarget_timer = retarget_interval
	var angle = Rng.randf() * TAU
	var distance = Rng.randf_range(16.0, wander_radius)
	_target_position = _origin + Vector2(cos(angle), sin(angle)) * distance
