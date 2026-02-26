extends State

func process_state_physics(_delta:float):
	auto_pilot.movement_goal_direction = Vector2(0,0)
	#ship.face_target(target_ship.get_center(), true)
	#ship.global_position = target_ship.to_global(ship.latching_position)
	#if abs(wrapf(ship._target_angle - ship.global_rotation, -PI, PI)) <= 0.19:
		#for cannon in ship.get_cannons():
			#cannon.gun.shoot(5)
