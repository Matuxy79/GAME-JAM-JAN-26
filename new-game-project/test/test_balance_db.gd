extends GutTest

# Test suite for BalanceDB class
# Tests external data structure loading and access

func before_all():
	# Ensure BalanceDB is initialized before tests
	if not Engine.has_singleton("BalanceDB"):
		add_child_autoload("BalanceDB")

func test_load_weapon_data():
	"""Test that weapon data loads correctly from external JSON"""
	var weapon_data = BalanceDB.get_weapon_data("basic_laser")
	assert_not_null(weapon_data, "basic_laser weapon data should exist")
	assert_eq(weapon_data.damage, 10, "basic_laser should have 10 damage")
	assert_eq(weapon_data.fire_rate, 1.0, "basic_laser should have 1.0 fire rate")

func test_load_enemy_data():
	"""Test that enemy data loads correctly from external JSON"""
	var enemy_data = BalanceDB.get_enemy_data("basic_enemy")
	assert_not_null(enemy_data, "basic_enemy data should exist")
	assert_eq(enemy_data.health, 50, "basic_enemy should have 50 health")
	assert_eq(enemy_data.speed, 100, "basic_enemy should have 100 speed")

func test_load_powerup_data():
	"""Test that powerup data loads correctly from external JSON"""
	var powerup_data = BalanceDB.get_powerup_data("laser_beam")
	assert_not_null(powerup_data, "laser_beam powerup data should exist")
	assert_eq(powerup_data.name, "Laser Beam", "laser_beam should be named 'Laser Beam'")
	assert_eq(powerup_data.effect, "fire_rate_multiplier", "laser_beam should increase fire rate")

func test_invalid_data():
	"""Test behavior with invalid data requests"""
	var invalid_weapon = BalanceDB.get_weapon_data("nonexistent_weapon")
	assert_eq(typeof(invalid_weapon), TYPE_NIL, "Invalid weapon should return null")
	
	var invalid_enemy = BalanceDB.get_enemy_data("nonexistent_enemy")
	assert_eq(typeof(invalid_enemy), TYPE_NIL, "Invalid enemy should return null")
