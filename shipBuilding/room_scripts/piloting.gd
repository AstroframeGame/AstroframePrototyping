extends Room

func _ready() -> void:
	super._ready()

# this method is searched by name from the player
func handle_input(event:InputEvent):
	if event.is_action_pressed("ship_fire"):
		shoot_all_cannons()

# this method is searched by name from the player
func move_ship(direction : Vector2):
	# pass up to the ship
	# move by speed and face the mouse.
	pass

func shoot_all_cannons():
	for child in ship.get_children():
		if child is Cannon:
			child.gun.shoot()
