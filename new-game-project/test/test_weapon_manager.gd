extends GutTest

# Tests for WeaponManager firing behavior

class MockWeaponManager extends preload("res://src/scripts/controller/player/WeaponManager.gd"):
	var last_damage: float = -1.0
	var spawn_calls: int = 0
	func spawn_projectile(_weapon_name: String, weapon_data: Dictionary, _direction: Vector2):
		# Override to avoid Pools dependency and capture computed damage
		last_damage = weapon_data.get("damage", 0) * damage_multiplier * temp_damage_multiplier
		spawn_calls += 1

func before_all():
	if not Engine.has_singleton("BalanceDB"):
		add_child_autoload("BalanceDB")
	if not Engine.has_singleton("EventBus"):
		add_child_autoload("EventBus")

func test_fire_sets_cooldown_and_blocks_spam():
	var wm := MockWeaponManager.new()
	wm.weapons = ["basic_laser"]
	wm.current_weapon_index = 0
	wm.damage_multiplier = 1.0
	wm.setup_weapons()
	wm.fire_current_weapon()

	assert_true(wm.fire_timers["basic_laser"] > 0, "Fire should set cooldown timer")
	assert_eq(wm.spawn_calls, 1, "First fire should spawn a projectile")

	# Immediate second fire should be blocked by cooldown
	wm.last_damage = -1.0
	wm.fire_current_weapon()
	assert_eq(wm.spawn_calls, 1, "Cooldown should prevent immediate second shot")

func test_damage_uses_balance_data():
	var wm := MockWeaponManager.new()
	wm.weapons = ["basic_laser"]
	wm.current_weapon_index = 0
	wm.damage_multiplier = 1.0
	wm.setup_weapons()
	wm.fire_current_weapon()

	var weapon_data = BalanceDB.get_weapon_data("basic_laser")
	var expected_damage = weapon_data.get("damage", 0)
	assert_eq(wm.last_damage, expected_damage, "Damage should use BalanceDB weapon damage")

