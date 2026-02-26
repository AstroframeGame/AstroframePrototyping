extends State

func enter_state():
	super()
	nav_agent.target_position = target_ship.get_center()

func process_state_physics(_delta:float):
	if not nav_agent.is_navigation_finished():
		nav_agent.target_position = target_ship.get_center()
		var path_point = nav_agent.get_next_path_position()
		var path_dir = (ship.get_center() - path_point).normalized()
		auto_pilot.movement_goal_direction = -path_dir
		auto_pilot.rotation_goal_direction = (ship.get_center() - target_ship.get_center()).angle() - PI/2

func exit_state():
	auto_pilot.latching_position = target_ship.to_local(ship.get_center())
