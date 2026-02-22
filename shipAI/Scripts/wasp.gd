class_name Wasp
extends Smart_Ship

func _ready() -> void:
	super()
	_aligning_speed_scalar = 400

func _physics_process(_delta: float) -> void:
	if not engines or not piloting:
		return
	update_state()
	process_state()
	
func update_state() -> void:
	if target == null:
		current_state = State.IDLE
		return
	@warning_ignore("integer_division")
	if hit_points < max_hit_points/2:
		current_state = State.FLEEING
		return
		
	_latching_position = target.to_local(piloting.global_position)
	# for some reason going align>latch>approach
	if distance_to_target() > 800:
		current_state = State.APPROACHING
	elif distance_to_target() < 700:
		if current_state == State.APPROACHING:
			current_state = State.ALIGNING
		elif current_state == State.ALIGNING:
			if abs(wrapf(_target_angle - global_rotation, -PI, PI)) <= 0.03:
					current_state = State.LATCHING

func _on_detection_range_body_entered(body: Node2D) -> void:
	if body.is_in_group("player_ship"):
		detection_timer.start()
	
func _on_detection_range_body_exited(body: Node2D) -> void:
	if body.is_in_group("player_ship"):
		target = null
		detection_timer.stop()
