## ColonyResources script. does game stuff in a simple way.
extends RefCounted
class_name ColonyResources

# Global colony stockpile: food, wood, exotic. Pure model - broadcasts every
# change through EventBus so the HUD stays in sync without direct refs.

var amounts: Dictionary = {"food": 10, "wood": 0, "exotic": 0}

# Add resources (harvest deposits, hawking shards...)
func add(kind: String, amount: int) -> void:
	if amount <= 0:
		return
	amounts[kind] = int(amounts.get(kind, 0)) + amount
	EventBus.colony_resources_changed.emit(amounts)

# Try to take resources; false when there is not enough
func take(kind: String, amount: int) -> bool:
	var have := int(amounts.get(kind, 0))
	if have < amount:
		return false
	amounts[kind] = have - amount
	EventBus.colony_resources_changed.emit(amounts)
	return true

# How much of a resource we have
func get_amount(kind: String) -> int:
	return int(amounts.get(kind, 0))
