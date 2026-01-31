## Rng script. does game stuff in a simple way.
extends Node

# Dice roller with a seed so we can repeat stuff.

var rng: RandomNumberGenerator
var seed_value: int = 0

func _ready():
	print("RNG initialized")
	rng = RandomNumberGenerator.new()
	set_seed(0)  # Default seed

func set_seed(new_seed: int):
	seed_value = new_seed
	rng.seed = new_seed
	print("RNG seed set to: ", new_seed)

func get_seed() -> int:
	return seed_value

# Random number generation
func randf() -> float:
	return rng.randf()

func randf_range(from: float, to: float) -> float:
	return rng.randf_range(from, to)

func randi() -> int:
	return rng.randi()

func randi_range(from: int, to: int) -> int:
	return rng.randi_range(from, to)

# Weighted random selection
func weighted_random(weights: Array[float]) -> int:
	var total_weight: float = 0.0
	for weight in weights:
		total_weight += weight
	
	var random_value = randf() * total_weight
	var current_weight: float = 0.0
	
	for i in range(weights.size()):
		current_weight += weights[i]
		if random_value <= current_weight:
			return i
	
	return weights.size() - 1

# Random selection from array
func random_choice(array: Array) -> Variant:
	if array.is_empty():
		return null
	return array[randi_range(0, array.size() - 1)]

# Shuffle array in place
func shuffle_array(array: Array) -> Array:
	for i in range(array.size() - 1, 0, -1):
		var j = randi_range(0, i)
		var temp = array[i]
		array[i] = array[j]
		array[j] = temp
	return array

# Random point in circle
func random_point_in_circle(radius: float) -> Vector2:
	var angle = randf() * 2.0 * PI
	var distance = randf() * radius
	return Vector2(cos(angle), sin(angle)) * distance

# Random point in rectangle
func random_point_in_rect(rect: Rect2) -> Vector2:
	return Vector2(
		randf_range(rect.position.x, rect.position.x + rect.size.x),
		randf_range(rect.position.y, rect.position.y + rect.size.y)
	)
