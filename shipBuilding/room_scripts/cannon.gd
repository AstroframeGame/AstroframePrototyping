class_name Cannon
extends Room

@onready var gun : GunHex = $GunHex
@export var damage = 20

func shoot():
	if is_multiplayer_authority():
		gun.shoot(damage)
		sync_shooting.rpc(damage)

@rpc("authority", "call_remote", "reliable")
func sync_shooting(dmg: int):
	if power_level > 0:
		gun.shoot(damage)
	else:
		blink_red()
