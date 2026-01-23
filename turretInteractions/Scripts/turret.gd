class_name Turret
extends Room

@onready var gun : Sprite2D = $Gun

func _ready() -> void:
	$Seat.seat_unhandled_input.connect(handle_seat_input)
	super._ready()

func handle_seat_input(event:InputEvent):
	# mouse guided system
	if event.is_action("grapple"):
		gun.shoot()
	
	if event is InputEventMouse:
		var mouse_pos = event.global_position
		
		
