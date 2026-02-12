class_name Bumble_Bee
extends Smart_Ship

''' TODO:
* create signal for when a room is at least half destroyed
* State=FLEE when that happens
'''

func _ready() -> void:
	super()

func _physics_process(_delta: float) -> void:
	if not engines or not piloting:
		return
	update_state()
	process_state()

func update_state() -> void:
	if target == null:
		current_state = State.IDLE
	else:
		if nav_agent.is_target_reached():
			if current_state == State.APPROACHING:
				_latching_position = target.to_local(piloting.global_position)
				current_state = State.ALIGNING
			elif current_state == State.ALIGNING:
				var look_dir = -(piloting.global_position - target.global_position)
				if abs(look_dir.angle() - rotation) <= PI/2:
					current_state = State.LATCHING
		else:
			nav_agent.target_position = target.get_piloting().global_position
			current_state = State.APPROACHING
			
	if hit_points < max_hit_points/2:
		current_state = State.FLEEING

func _on_detection_range_body_entered(body: Node2D) -> void:
	if body.is_in_group("player_ship"):
		detection_timer.start()
	
func _on_detection_range_body_exited(body: Node2D) -> void:
	if body.is_in_group("player_ship"):
		target = null
		detection_timer.stop()
