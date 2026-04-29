class_name SwivelCannon
extends Room

@onready var gun : GunHex = $GunHex
@export var damage = 20
var firing : bool = false

func _process(_delta: float) -> void:
	if firing:
		shoot()

func shoot():
	if power_level > 0:
		gun.shoot(damage)
	else:
		blink_red()

func handle_input(_event:InputEvent):
	if not power_level > 0:
		blink_red()
		return
	# mouse guided system
	if InputHelper.using_mouse:
		gun.gunSprite.look_at(get_global_mouse_position())
	else:
		var d = InputHelper.controller_look
		if d.length() > 0.5:
			gun.gunSprite.rotation = atan2(-d.y, -d.x) + deg_to_rad(30) + global_rotation
