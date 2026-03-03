extends Ship

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	#var piloting : Piloting = get_piloting()
	#if piloting and piloting.seat.controlled_by:
	#rotate_ship(state)
	move_ship(state)

func move_ship(state: PhysicsDirectBodyState2D):
	state.linear_velocity = Vector2.DOWN * 75
