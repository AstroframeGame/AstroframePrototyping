class_name SwivelCannon
extends Room

@onready var gun : GunHex = $GunHex
@export var damage = 20
var firing : bool = false

func shoot():
	if power_level > 0:
		gun.shoot(damage)
	else:
		blink_red()

func handle_input(event:InputEvent):
	if not power_level > 0:
		blink_red()
		return
	# mouse guided system
	if event.is_action_pressed("ship_fire"):
		firing = true
	if event.is_action_released("ship_fire"):
		firing = false
		
	if InputHelper.using_mouse:
		gun.gunSprite.look_at(get_global_mouse_position())
	else:
		var d = InputHelper.controller_look
		if d.length() > 0.5:
			gun.gunSprite.rotation = atan2(-d.y, -d.x) + deg_to_rad(30) + global_rotation
