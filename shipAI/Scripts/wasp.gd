class_name Wasp
extends Smart_Ship

func _physics_process(_delta: float) -> void:
	if not engines or not piloting:
		return
	update_state()
	process_state()
	
#func _on_navigation_agent_2d_velocity_computed(safe_velocity: Vector2) -> void:
	#linear_velocity = safe_velocity

func update_state() -> void:
	if target == null:
		current_state = State.IDLE
	else:
		if distance_to_target() < 700:
			if current_state == State.APPROACHING:
				_latching_position = target.to_local(piloting.global_position)
				current_state = State.ALIGNING
			elif current_state == State.ALIGNING:
				if abs(wrapf(_target_angle - global_rotation, -PI, PI)) <= 0.01:
					current_state = State.LATCHING
		else:
			current_state = State.APPROACHING

	@warning_ignore("integer_division")
	if hit_points < max_hit_points/2:
		current_state = State.FLEEING

func _on_detection_range_body_entered(body: Node2D) -> void:
	if body.is_in_group("player_ship"):
		detection_timer.start()
	
func _on_detection_range_body_exited(body: Node2D) -> void:
	if body.is_in_group("player_ship"):
		target = null
		detection_timer.stop()
