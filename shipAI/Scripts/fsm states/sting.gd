extends State

func process_state_physics(_delta:float):
	if not target_ship:
		controller.change_state(controller.idle_state)
		return
	
	var latching_dir = target_ship.to_global(auto_pilot.latching_position) - ship.get_center()
	auto_pilot.movement_goal_direction = latching_dir.normalized()
	
	auto_pilot.rotation_goal_direction = (ship.get_center() - target_ship.get_center()).angle() + PI/2
	
	# ikik magic numbers blah blah ¯\_(ツ)_/¯
	if abs(wrapf(auto_pilot.rotation_goal_direction - ship.global_rotation, -PI, PI)) <= 0.19:
		for cannon in ship.get_cannons():
			cannon.gun.shoot(5)
