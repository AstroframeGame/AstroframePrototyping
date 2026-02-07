class_name Engines
extends Room

# just for forward
@export var boost_thrust = 12
# for back, and sides
@export var standard_thrust = 100
# for rotation
@export var rotational_thrust = 0.2

@export var max_speed = 100

func get_boost_thrust() -> float:
	return boost_thrust * power_level
	
func get_thrust() -> float:
	return standard_thrust * power_level

func get_rotational_thrust() -> float:
	return rotational_thrust * power_level * power_level

func get_max_speed() -> float:
	return max_speed
