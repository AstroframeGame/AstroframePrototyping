extends Room
class_name Shields_Room


# should probably create a shield as a rb and pin it to the ship instead
# not sure of the correct approach or what type of body it should be.

# check power_level to change the shield recharge speed

@export var recharge_speed = 30
@export var max_shield_durability = 100

@onready var shield: Shield = $Shield

func  _ready() -> void:
	on_power_level_change.connect(on_power_change)
	on_power_change(self)

func on_power_change(_room):
	recharge_speed = 10 * power_level
	shield.set_active(power_level > 0)
	# smooth this later with a coroutine
