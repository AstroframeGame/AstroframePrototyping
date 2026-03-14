extends State

func enter_state():
	super()
	auto_pilot.movement_goal_direction = Vector2(0,0)
	auto_pilot.rotation_goal = 0.0
	
	# search area for target
	if not auto_pilot.is_active():
		return

	for body in auto_pilot.detection_area.get_overlapping_bodies():
		if body.is_in_group("player_ship"):
			pass
