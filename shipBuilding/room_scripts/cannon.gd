class_name Cannon
extends Room

@onready var gun : GunHex = $Gun
@export var damage = 20

func shoot():
	if power_level > 0:
		gun.shoot(damage)
