extends GutTest

# Tests for player-related components and health behavior

func before_all():
	if not Engine.has_singleton("BalanceDB"):
		add_child_autoload("BalanceDB")
	if not Engine.has_singleton("EventBus"):
		add_child_autoload("EventBus")

func test_health_component_damage_and_death():
	var HealthComponent = preload("res://src/scripts/model/player/HealthComponent.gd")
	var health := HealthComponent.new()
	health.max_health = 50
	health.current_health = 50
	var died_called := false
	health.died.connect(func(): died_called = true)
	health.take_damage(60)
	assert_eq(health.current_health, 0, "Health should clamp at 0 when overkilled")
	assert_true(died_called, "Death signal should fire when health reaches 0")

func test_health_component_heal_caps_at_max():
	var HealthComponent = preload("res://src/scripts/model/player/HealthComponent.gd")
	var health := HealthComponent.new()
	health.max_health = 40
	health.current_health = 40
	health.take_damage(15)
	health.heal(30)
	assert_eq(health.current_health, 40, "Healing should not exceed max health")

