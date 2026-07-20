## ColonyWorld script. hosts colony entities and controller nodes.
extends Node2D
class_name ColonyWorld

@onready var colonist_manager: ColonistManager = $ColonistManager

func _ready():
	print("ColonyWorld initialized with ", colonist_manager.test_colonist_count, " test colonists")
