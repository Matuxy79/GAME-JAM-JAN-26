## DefDatabase script. does game stuff in a simple way.
extends Node

# Mod-friendly def loader. Core defs live in res://src/resources/defs/*.json,
# player mods live in user://mods/<mod_name>/defs/*.json. Every file declares
# a def type and a dict of defs keyed by id. Later loads override earlier ones
# by id, so mods can patch core content. See MODDING.md at the project root.

const CORE_DEFS_DIR := "res://src/resources/defs"
const MODS_DIR := "user://mods"

# { def_type: { id: def_dict } }
var _defs: Dictionary = {}
var load_errors: Array[String] = []

func _ready():
	print("DefDatabase initialized")
	reload()

# Wipe and load core defs, then mods on top
func reload() -> void:
	_defs = {}
	load_errors = []
	_load_defs_from_dir(CORE_DEFS_DIR, "core")
	_load_mods()

# Grab one def (empty dict if missing)
func get_def(def_type: String, id: String) -> Dictionary:
	var bucket: Dictionary = _defs.get(def_type, {})
	return bucket.get(id, {})

# Grab all defs of a type
func get_defs(def_type: String) -> Dictionary:
	return _defs.get(def_type, {})

# True if a def exists
func has_def(def_type: String, id: String) -> bool:
	return _defs.get(def_type, {}).has(id)

# All def types currently loaded
func get_def_types() -> Array:
	return _defs.keys()

# Scan user://mods/*/defs/*.json in folder name order
func _load_mods() -> void:
	var dir := DirAccess.open(MODS_DIR)
	if dir == null:
		return
	var mod_names: Array[String] = []
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if dir.current_is_dir() and not entry.begins_with("."):
			mod_names.append(entry)
		entry = dir.get_next()
	dir.list_dir_end()
	mod_names.sort()
	for mod_name in mod_names:
		_load_defs_from_dir(MODS_DIR + "/" + mod_name + "/defs", mod_name)

# Load every *.json def file in a folder
func _load_defs_from_dir(path: String, source: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		if source == "core":
			push_error("DefDatabase: core defs folder missing: " + path)
		return
	var files: Array[String] = []
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if not dir.current_is_dir() and entry.ends_with(".json"):
			files.append(entry)
		entry = dir.get_next()
	dir.list_dir_end()
	files.sort()
	for file_name in files:
		_load_def_file(path + "/" + file_name, source)

# Parse and merge one def file
func _load_def_file(file_path: String, source: String) -> void:
	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		_record_error("cannot open " + file_path)
		return
	var json_string := file.get_as_text()
	file.close()

	var json := JSON.new()
	if json.parse(json_string) != OK:
		_record_error("bad JSON in %s (line %d): %s" % [file_path, json.get_error_line(), json.get_error_message()])
		return
	if typeof(json.data) != TYPE_DICTIONARY:
		_record_error("root of " + file_path + " must be an object")
		return

	var data: Dictionary = json.data
	if not data.has("type") or typeof(data.get("type")) != TYPE_STRING:
		_record_error(file_path + " is missing string field 'type'")
		return
	if not data.has("defs") or typeof(data.get("defs")) != TYPE_DICTIONARY:
		_record_error(file_path + " is missing object field 'defs'")
		return

	var def_type: String = data["type"]
	if not _defs.has(def_type):
		_defs[def_type] = {}
	var bucket: Dictionary = _defs[def_type]
	var defs: Dictionary = data["defs"]
	for id in defs.keys():
		if typeof(defs[id]) != TYPE_DICTIONARY:
			_record_error("%s def '%s' in %s must be an object" % [def_type, id, file_path])
			continue
		if bucket.has(id) and source != "core":
			print("DefDatabase: mod '%s' overrides %s/%s" % [source, def_type, id])
		bucket[id] = defs[id]
	print("DefDatabase: loaded %d %s defs from %s" % [defs.size(), def_type, file_path])

# Log a load error but keep going
func _record_error(message: String) -> void:
	load_errors.append(message)
	push_error("DefDatabase: " + message)
