class_name Cannon
extends Room

@onready var gun : GunHex = $Gun

func shoot():
	if power_level > 0:
		gun.shoot()
