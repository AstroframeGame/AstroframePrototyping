extends State

func enter_state():
	super()
	ship = controller.ship
	target = ship.target
	nav_agent = controller.nav_agent
	nav_agent.target_position = target.get_piloting().global_position

func process_state_physics(_delta:float):
	if not nav_agent.is_navigation_finished():
		nav_agent.target_position = target.get_piloting().global_position
		var path_point = nav_agent.get_next_path_position()
		var path_dir = ship.piloting.global_position - path_point
		ship.face_target(path_point, false)
		
		var desired_velocity = path_dir.normalized()
		desired_velocity *= ship.standard_thrust
		desired_velocity /= ship.mass
		
		var vel_delta = -(desired_velocity - ship.safe_vel).normalized()
		ship.apply_central_force(vel_delta * ship.standard_thrust / ship.mass)

func exit_state():
	ship.latching_position = target.to_local(ship.piloting.global_position)
