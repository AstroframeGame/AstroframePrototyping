extends State

func enter_state():
	super()
	ship = controller.ship
	target = ship.target

func process_state_physics(_delta:float):
	ship.face_target(target.get_piloting().global_position, true)
	ship.linear_velocity = -ship.look_dir.normalized() 
	ship.linear_velocity *= ship.standard_thrust
	ship.linear_velocity /= ship.mass
