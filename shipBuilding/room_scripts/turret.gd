class_name Turret
extends Room

@onready var gun : Sprite2D = $Gun

func _ready() -> void:
	super._ready()

func handle_input(event:InputEvent):
	# mouse guided system
	if event.is_action("ship_fire"):
		gun.shoot()
	
	if event is InputEventMouse:
		gun.gunSprite.look_at(get_global_mouse_position())
		
