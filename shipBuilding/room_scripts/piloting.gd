class_name Piloting
extends Room

@onready var seat: SeatInteractable = $SeatHex/SeatInteractable

# this method is searched by name from the player
func handle_input(event:InputEvent):
	if event.is_action_pressed("ship_fire"):
		shoot_all_cannons()
		return
	ship.handle_input(event)

# this method is searched by name from the player
func move_ship(direction : Vector2, delta):
	ship.move_ship(direction, delta)

func shoot_all_cannons():
	for child in ship.get_children():
		if child is Cannon:
			child.gun.shoot()
