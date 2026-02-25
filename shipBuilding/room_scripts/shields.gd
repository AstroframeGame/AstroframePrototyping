extends Room
class_name Shields_Room

'''
* shield holds take_damage & health
* when shield dies, it stays down
* start a timer based on recharge_speed
* when timer ends, shield comes back up
'''

#@export var recharge_speed = 30
@export var recharge_speeds := [-1, 7.5, 5, 2.5]
@export var max_shield_durability = 100

@onready var shield: Shield = $Shield
@onready var recharge_timer : Timer = $RechargeTimer

func  _ready() -> void:
	on_power_level_change.connect(on_power_change)
	shield.on_shield_broken.connect(recharge_shield)
	recharge_timer.timeout.connect(deploy_shield)
	on_power_change(self)
	
	shield.durability = max_shield_durability

func on_power_change(_room):
	if shield.durability == max_shield_durability:
		shield.set_active(power_level > 0)

func recharge_shield():
	recharge_timer.start(recharge_speeds[power_level])

func deploy_shield():
	shield.durability = max_shield_durability
	shield.set_active(power_level > 0)
