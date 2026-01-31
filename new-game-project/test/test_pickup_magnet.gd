extends GutTest

# Tests for PickupMagnet collection behavior

class DummyGem extends Node2D:
	var collected := false
	func collect():
		collected = true
	func is_collected():
		return collected

func before_all():
	if not Engine.has_singleton("EventBus"):
		add_child_autoload("EventBus")

func test_collects_when_within_range():
	var magnet = preload("res://src/scripts/model/player/PickupMagnet.gd").new()
	var parent = Node2D.new()
	magnet.pickup_range = 80.0
	magnet.collection_range = 20.0
	parent.add_child(magnet)
	get_tree().current_scene.add_child(parent)
	
	var gem := DummyGem.new()
	gem.global_position = Vector2(10, 0)
	get_tree().current_scene.add_child(gem)
	
	magnet.collect_xp_gem(gem)
	assert_true(gem.collected, "Gem within collection range should be collected immediately")

func test_attract_moves_far_gem_closer():
	var magnet = preload("res://src/scripts/model/player/PickupMagnet.gd").new()
	var parent = Node2D.new()
	parent.global_position = Vector2.ZERO
	magnet.pickup_range = 80.0
	magnet.collection_range = 20.0
	magnet.attraction_speed = 100.0
	parent.add_child(magnet)
	get_tree().current_scene.add_child(parent)
	
	var gem := DummyGem.new()
	gem.global_position = Vector2(60, 0)
	get_tree().current_scene.add_child(gem)
	
	magnet.attract_xp_gem(gem, 0.1)
	assert_true(gem.global_position.x < 60, "Gem farther than collection range should move closer but not instantly collect")
	assert_false(gem.collected, "Far gem should not be collected in first attract step")

