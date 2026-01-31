## Save script. does game stuff in a simple way.
extends Node

# Save file helper. Keeps basic player stuff.

const SAVE_FILE = "user://savegame.save"

var save_data: Dictionary = {
	"player_level": 1,
	"player_xp": 0,
	"player_health": 100,
	"max_health": 100,
	"weapons_unlocked": [],
	"perks_selected": [],
	"game_time": 0.0,
	"high_score": 0,
	"settings": {
		"master_volume": 1.0,
		"sfx_volume": 1.0,
		"music_volume": 1.0
	}
}

func _ready():
	print("Save system initialized")
	load_game()

func save_game():
	var file = FileAccess.open(SAVE_FILE, FileAccess.WRITE)
	if file == null:
		push_error("Failed to open save file for writing")
		return false
	
	file.store_string(JSON.stringify(save_data))
	file.close()
	print("Game saved successfully")
	return true

func load_game():
	if not FileAccess.file_exists(SAVE_FILE):
		print("No save file found, using defaults")
		return false
	
	var file = FileAccess.open(SAVE_FILE, FileAccess.READ)
	if file == null:
		push_error("Failed to open save file for reading")
		return false
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		push_error("Failed to parse save file JSON")
		return false
	
	save_data = json.data
	print("Game loaded successfully")
	return true

func get_save_data(key: String, default_value = null):
	return save_data.get(key, default_value)

func set_save_data(key: String, value):
	save_data[key] = value

func reset_save_data():
	save_data = {
		"player_level": 1,
		"player_xp": 0,
		"player_health": 100,
		"max_health": 100,
		"weapons_unlocked": [],
		"perks_selected": [],
		"game_time": 0.0,
		"high_score": 0,
		"settings": {
			"master_volume": 1.0,
			"sfx_volume": 1.0,
			"music_volume": 1.0
		}
	}
	save_game()
