class_name Engines
extends Room

# just for forward
@export var boost_thrust = 12
@export var forward_multiplier = 2
# for back, and sides
@export var standard_thrust = 1200
# for rotation
@export var rotational_thrust = 0.2

@export var max_speed = 10000

func _ready() -> void:
	super._ready()
	on_power_level_change.connect(on_power_changed)

func get_boost_thrust() -> float:
	return boost_thrust * power_level
	
func get_thrust() -> float:
	return standard_thrust * power_level

func get_rotational_thrust() -> float:
	return rotational_thrust * power_level * power_level

func get_max_speed() -> float:
	return max_speed

func on_power_changed(_room):
	$Trail2D.visible = power_level > 0
	$Trail2D2.visible = power_level > 0
	pass
