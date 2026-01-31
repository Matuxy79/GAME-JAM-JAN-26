## WorldMap - PCG chunk streaming tilemap
extends TileMapLayer
class_name WorldMap

const CHUNK_SIZE := 16  # tiles per chunk
const TILE_SIZE := 16   # pixels per tile
const LOAD_RADIUS := 3  # chunks around player

var loaded_chunks: Dictionary = {}  # Vector2i -> bool
var player: Node2D

func _ready():
	print("WorldMap initialized - Chunk size: ", CHUNK_SIZE, " tiles, Load radius: ", LOAD_RADIUS)
	find_player()

func _process(_delta):
	if not player or not is_instance_valid(player):
		find_player()
		return
	update_chunks()

func update_chunks():
	var player_chunk = world_to_chunk(player.global_position)

	# Load chunks in radius
	for x in range(-LOAD_RADIUS, LOAD_RADIUS + 1):
		for y in range(-LOAD_RADIUS, LOAD_RADIUS + 1):
			var chunk_pos = player_chunk + Vector2i(x, y)
			if not loaded_chunks.has(chunk_pos):
				load_chunk(chunk_pos)

	# Unload distant chunks
	var chunks_to_unload: Array[Vector2i] = []
	for chunk_pos in loaded_chunks.keys():
		var dist = abs(chunk_pos.x - player_chunk.x) + abs(chunk_pos.y - player_chunk.y)
		if dist > LOAD_RADIUS + 2:
			chunks_to_unload.append(chunk_pos)

	for chunk_pos in chunks_to_unload:
		unload_chunk(chunk_pos)

func load_chunk(chunk_pos: Vector2i):
	var base_tile = chunk_pos * CHUNK_SIZE
	for x in range(CHUNK_SIZE):
		for y in range(CHUNK_SIZE):
			var tile_pos = base_tile + Vector2i(x, y)
			# Use atlas coord (0,0) for sand tile - first tile in tileset
			set_cell(tile_pos, 0, Vector2i(0, 0))
	loaded_chunks[chunk_pos] = true

func unload_chunk(chunk_pos: Vector2i):
	var base_tile = chunk_pos * CHUNK_SIZE
	for x in range(CHUNK_SIZE):
		for y in range(CHUNK_SIZE):
			var tile_pos = base_tile + Vector2i(x, y)
			erase_cell(tile_pos)
	loaded_chunks.erase(chunk_pos)

func world_to_chunk(world_pos: Vector2) -> Vector2i:
	var chunk_pixel_size = CHUNK_SIZE * TILE_SIZE
	return Vector2i(
		int(floor(world_pos.x / chunk_pixel_size)),
		int(floor(world_pos.y / chunk_pixel_size))
	)

func find_player():
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

func get_loaded_chunk_count() -> int:
	return loaded_chunks.size()
