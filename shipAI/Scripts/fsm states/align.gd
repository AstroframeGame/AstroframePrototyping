extends State

var target : Ship
var ship : Smart_Ship

func enter_state():
	super()
	target = controller.ship.target
	ship = controller.ship

func process_state_physics(_delta:float):
	ship.face_target(target.global_position, true)
	ship.global_position = target.to_global(ship.latching_position)
	if abs(wrapf(ship._target_angle - ship.global_rotation, -PI, PI)) <= 0.19:
		for cannon in ship.get_cannons():
			cannon.gun.shoot(5)
