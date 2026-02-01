## MovementComponent script. does game stuff in a simple way.
extends Node
class_name MovementComponent

# MovementComponent - Handles player input and movement
# Separated for modularity and easier testing

@export var speed: float = 40.0
@export var acceleration: float = 10.0
@export var friction: float = 10.0

var input_vector: Vector2 = Vector2.ZERO
var parent: CharacterBody2D

func _ready():
	parent = get_parent()
	if not parent is CharacterBody2D:
		push_error("MovementComponent must be attached to a CharacterBody2D")
	
	# Ensure movement input actions exist and support both arrow keys and WASD.
	# This lets us configure controls in code instead of relying only on editor setup.
	_setup_input_map()

func _setup_input_map() -> void:
	# Movement actions we care about
	var actions := [
		"move_up",
		"move_down",
		"move_left",
		"move_right",
	]

	# Ensure actions exist
	for action_name in actions:
		if not InputMap.has_action(action_name):
			InputMap.add_action(action_name)

	# Bind arrow keys + WASD to movement actions
	_ensure_key("move_up", KEY_UP)
	_ensure_key("move_up", KEY_W)

	_ensure_key("move_down", KEY_DOWN)
	_ensure_key("move_down", KEY_S)

	_ensure_key("move_left", KEY_LEFT)
	_ensure_key("move_left", KEY_A)

	_ensure_key("move_right", KEY_RIGHT)
	_ensure_key("move_right", KEY_D)

func _ensure_key(action_name: String, keycode: int) -> void:
	# Adds a key event to an action if it is not already present.
	var ev := InputEventKey.new()
	ev.keycode = keycode
	if not InputMap.action_has_event(action_name, ev):
		InputMap.action_add_event(action_name, ev)

func process_movement(delta: float):
	if not parent:
		return
	
	handle_input()
	apply_movement(delta)

func handle_input():
	input_vector = Vector2.ZERO
	
	# Get input direction
	if Input.is_action_pressed("move_right"):
		input_vector.x += 1
	if Input.is_action_pressed("move_left"):
		input_vector.x -= 1
	if Input.is_action_pressed("move_down"):
		input_vector.y += 1
	if Input.is_action_pressed("move_up"):
		input_vector.y -= 1
	
	# Normalize diagonal movement
	if input_vector.length() > 0:
		input_vector = input_vector.normalized()

func apply_movement(delta: float):
	if not parent:
		return
	
	# Apply movement with acceleration
	if input_vector.length() > 0:
		parent.velocity = parent.velocity.move_toward(input_vector * speed, acceleration * speed * delta)
	else:
		# Apply friction when not moving
		parent.velocity = parent.velocity.move_toward(Vector2.ZERO, friction * speed * delta)
	
	# Move the character
	parent.move_and_slide()

func get_movement_direction() -> Vector2:
	return input_vector

func is_moving() -> bool:
	return input_vector.length() > 0

func get_speed() -> float:
	return parent.velocity.length() if parent else 0.0
