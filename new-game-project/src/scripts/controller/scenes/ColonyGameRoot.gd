## ColonyGameRoot script. main root for colony phase gameplay loop.
extends Node2D
class_name ColonyGameRoot

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	print("ColonyGameRoot initialized")
	EventBus.game_started.emit()
	EventBus.colony_event_logged.emit("Colony simulation started.")
