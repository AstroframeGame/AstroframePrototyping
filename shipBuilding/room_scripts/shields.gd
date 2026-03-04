extends Room
class_name Shields_Room

#@export var recharge_speed = 30
@export var recharge_speeds := [-1, 7.5, 5, 2.5]
@export var max_shield_durability = [100,100,150,200]

@onready var shield: Shield = $Shield
@onready var recharge_timer : Timer = $RechargeTimer

func  _ready() -> void:
	super._ready()
	on_power_level_change.connect(on_power_change)
	shield.on_shield_broken.connect(recharge_shield)
	recharge_timer.timeout.connect(deploy_shield)
	on_power_change(self)
	
	shield.durability = max_shield_durability[0]

func on_power_change(_room):
	if recharge_timer.time_left <= 0:
		shield.set_active(power_level > 0)
	shield.durability = max_shield_durability[power_level]

func recharge_shield():
	recharge_timer.start(recharge_speeds[power_level])

func deploy_shield():
	shield.durability = max_shield_durability[power_level]
	shield.set_active(power_level > 0)
