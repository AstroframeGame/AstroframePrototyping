class_name Autopilot
extends Room

func shoot_all_cannons():
	for child in ship.get_children():
		if child is Cannon:
			child.shoot()

func is_active() -> bool:
	return power_level > 0

func get_goal_velocity(current_velocity: Vector2) -> Vector2:
	var engines = ship.get_engines()
	if not engines:
		return Vector2.ZERO
	
	var goal_vel = current_velocity
	# set this to the goal direction. use current vel to not overshoot
	# dirs/deltas will be normalized. here ↓
	goal_vel = goal_vel.normalized() * min(goal_vel.length(), engines.get_max_speed())
	return goal_vel

func is_idling() -> bool:
	# returns whether it should be sitting still
	return false

func get_goal_angular_velocity() -> float:
	var engines = ship.get_engines()
	if not engines:
		return 0.0
		
	var rot_input = 0.0 # set this to sign(delta rotation) * fun constant
	# def needs to be updated to be normalized, but not now. 
	return rot_input * engines.get_rotational_thrust()
