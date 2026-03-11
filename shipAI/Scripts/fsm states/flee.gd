extends State

var dir_vector:Vector2 

func process_state_physics(_delta:float):
	if target_ship:
		dir_vector = ship.get_center() - target_ship.get_center()
	else:
		if ship:
			dir_vector = ship.transform.x
	auto_pilot.movement_goal_direction = (dir_vector).normalized()
	auto_pilot.rotation_goal = (dir_vector).angle() + PI/2
