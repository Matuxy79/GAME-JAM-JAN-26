## TerrainGenerator - Room-based terrain generation with weighted biomes
extends Node
class_name TerrainGenerator

# Biome types matching John's folder structure
# Weights: arid 50%, mixed 20%, green 15%, purple 15%
enum Biome { ARID_DESERT, MIXED_GROUND, GREEN_LUSH, PURPLE_BLOOM }

# Chunk size must match WorldMap
const CHUNK_SIZE := 16
const TILE_SIZE := 16

# Seed for deterministic generation
var world_seed: int = 0

# 9-grid position names for autotile
const POSITIONS_9GRID = [
	"top-left", "top-middle", "top-right",
	"middle-left", "middle-middle", "middle-right",
	"bottom-left", "bottom-middle", "bottom-right"
]

func _ready():
	world_seed = Rng.get_seed()
	print("TerrainGenerator initialized with seed: ", world_seed)

# Deterministic hash for chunk position
func hash_chunk(chunk_x: int, chunk_y: int) -> int:
	# Simple but effective hash combining position with seed
	var hash_val = world_seed
	hash_val = hash_val * 31 + chunk_x
	hash_val = hash_val * 31 + chunk_y
	hash_val = hash_val ^ (hash_val >> 16)
	hash_val = hash_val * 0x85ebca6b
	hash_val = hash_val ^ (hash_val >> 13)
	return abs(hash_val)

# Get biome for a chunk (room-based selection)
func get_room_biome(chunk_pos: Vector2i) -> Biome:
	var hash_val = hash_chunk(chunk_pos.x, chunk_pos.y)
	var roll = hash_val % 100

	# 50% arid, 20% mixed, 15% green, 15% purple
	if roll < 50:
		return Biome.ARID_DESERT
	elif roll < 70:
		return Biome.MIXED_GROUND
	elif roll < 85:
		return Biome.GREEN_LUSH
	else:
		return Biome.PURPLE_BLOOM

# Convert tile position to chunk position
func tile_to_chunk(tile_pos: Vector2i) -> Vector2i:
	return Vector2i(
		int(floor(float(tile_pos.x) / CHUNK_SIZE)),
		int(floor(float(tile_pos.y) / CHUNK_SIZE))
	)

# Get biome at a world position (delegates to room biome)
func get_biome_at(world_pos: Vector2) -> Biome:
	var tile_pos = Vector2i(int(floor(world_pos.x / TILE_SIZE)), int(floor(world_pos.y / TILE_SIZE)))
	var chunk_pos = tile_to_chunk(tile_pos)
	return get_room_biome(chunk_pos)

func get_biome_name(biome: Biome) -> String:
	match biome:
		Biome.ARID_DESERT:
			return "arid_desert"
		Biome.MIXED_GROUND:
			return "mixed_ground"
		Biome.GREEN_LUSH:
			return "green_lush"
		Biome.PURPLE_BLOOM:
			return "purple_bloom"
	return "arid_desert"

func get_tile_position_name(tile_pos: Vector2i, tile_size: int) -> String:
	var current_chunk = tile_to_chunk(tile_pos)
	var current_biome = get_room_biome(current_chunk)

	# Arid desert uses repeating left-middle-right pattern (no edge detection)
	if current_biome == Biome.ARID_DESERT:
		return get_arid_position(tile_pos)

	# Mixed ground uses random tiles (no specific pattern)
	if current_biome == Biome.MIXED_GROUND:
		return "middle-middle"  # Will be handled specially in WorldMap

	# Green lush and purple bloom use 9-grid edge detection at chunk boundaries
	return get_9grid_position(tile_pos, current_chunk, current_biome)

# Arid desert: left/middle/right based on x position within chunk
func get_arid_position(tile_pos: Vector2i) -> String:
	# Use absolute tile x position mod 3 for consistent pattern
	var col = abs(tile_pos.x) % 3
	match col:
		0: return "left"
		1: return "middle"
		2: return "right"
	return "middle"

# 9-grid position for green lush and purple bloom at room boundaries
func get_9grid_position(tile_pos: Vector2i, current_chunk: Vector2i, current_biome: Biome) -> String:
	# Check neighboring chunks for biome transitions
	var check_offsets = {
		"top": Vector2i(0, -1),
		"bottom": Vector2i(0, 1),
		"left": Vector2i(-1, 0),
		"right": Vector2i(1, 0)
	}

	# Get tile position within chunk (0 to CHUNK_SIZE-1)
	var local_x = tile_pos.x - (current_chunk.x * CHUNK_SIZE)
	var local_y = tile_pos.y - (current_chunk.y * CHUNK_SIZE)
	if local_x < 0:
		local_x += CHUNK_SIZE
	if local_y < 0:
		local_y += CHUNK_SIZE

	# Check if at chunk edge and if neighbor chunk has different biome
	var at_top_edge = local_y == 0
	var at_bottom_edge = local_y == CHUNK_SIZE - 1
	var at_left_edge = local_x == 0
	var at_right_edge = local_x == CHUNK_SIZE - 1

	var top_different = at_top_edge and get_room_biome(current_chunk + check_offsets["top"]) != current_biome
	var bottom_different = at_bottom_edge and get_room_biome(current_chunk + check_offsets["bottom"]) != current_biome
	var left_different = at_left_edge and get_room_biome(current_chunk + check_offsets["left"]) != current_biome
	var right_different = at_right_edge and get_room_biome(current_chunk + check_offsets["right"]) != current_biome

	# Determine row
	var row: String
	if top_different and not bottom_different:
		row = "top"
	elif bottom_different and not top_different:
		row = "bottom"
	else:
		row = "middle"

	# Determine column
	var col: String
	if left_different and not right_different:
		col = "left"
	elif right_different and not left_different:
		col = "right"
	else:
		col = "middle"

	return row + "-" + col

func get_biome_and_position(tile_pos: Vector2i, tile_size: int) -> Dictionary:
	var world_pos = Vector2(tile_pos) * tile_size
	var biome = get_biome_at(world_pos)
	var position_name = get_tile_position_name(tile_pos, tile_size)

	return {
		"biome": biome,
		"biome_name": get_biome_name(biome),
		"position": position_name
	}
