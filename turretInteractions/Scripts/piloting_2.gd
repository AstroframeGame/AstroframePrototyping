extends Room

func _ready() -> void:
	$Seat.seat_unhandled_input.connect(handle_seat_input)
	super._ready()
	
func handle_seat_input(event:InputEvent):
	if event.is_action_pressed("ui_accept"):
		shoot_all_cannons()

func shoot_all_cannons():
	for child in get_parent().get_children():
		if child is Cannon:
			child.gun.shoot()
