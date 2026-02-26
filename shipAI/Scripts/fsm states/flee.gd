extends State

func process_state_physics(_delta:float):
	print("fleeing")
	auto_pilot.goal_direction = Vector2(0,0)
	#ship.face_target(target_ship.get_center(), true)
	#ship.linear_velocity = -ship.look_dir.normalized() 
	#ship.linear_velocity *= ship.standard_thrust
	#ship.linear_velocity /= ship.mass
