## ColonistManager script. spawns and tracks test colonist pawns for colony loop.
extends Node
class_name ColonistManager

const PAWN_SCENE := preload("res://src/scenes/Pawn.tscn")

@export var test_colonist_count: int = 5
@export var spawn_center: Vector2 = Vector2(640, 360)
@export var spawn_radius: float = 120.0

@onready var colonists_root: Node2D = $"../Colonists"

var colonists: Array[Pawn] = []

func _ready():
	_spawn_test_colonists()

func _spawn_test_colonists():
	for child in colonists_root.get_children():
		child.queue_free()
	colonists.clear()

	for i in range(test_colonist_count):
		var pawn: Pawn = PAWN_SCENE.instantiate()
		pawn.pawn_name = "Colonist %d" % (i + 1)
		var angle = (TAU / max(float(test_colonist_count), 1.0)) * i
		var offset = Vector2(cos(angle), sin(angle)) * spawn_radius
		pawn.global_position = spawn_center + offset
		colonists_root.add_child(pawn)
		colonists.append(pawn)
		pawn.tree_exited.connect(_on_colonist_exited.bind(pawn))

	_emit_colonist_count()
	EventBus.colony_event_logged.emit("Spawned %d test colonists." % colonists.size())

func _on_colonist_exited(pawn: Pawn):
	colonists.erase(pawn)
	_emit_colonist_count()

func _emit_colonist_count():
	EventBus.colony_pawn_count_changed.emit(colonists.size())
