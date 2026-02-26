class_name Wasp
extends Smart_Ship

func _ready() -> void:
	super()

func _physics_process(_delta: float) -> void:
	if not engines or not piloting or not target:
		return
	if hit_points < float(max_hit_points)/2:
		if state_machine.current_state != state_machine.flee_state:
			state_machine.change_state(state_machine.flee_state)
			return

func _on_detection_range_body_entered(body: Node2D) -> void:
	if body.is_in_group("player_ship"):
		detection_timer.start()
	
func _on_detection_range_body_exited(body: Node2D) -> void:
	if body.is_in_group("player_ship"):
		target = null
		detection_timer.stop()
		state_machine.change_state(state_machine.idle_state)

func _on_navigation_agent_2d_velocity_computed(safe_velocity: Vector2) -> void:
	cache_safe_vel(safe_velocity)

func _on_navigation_agent_2d_navigation_finished() -> void:
	state_machine.change_state(state_machine.align_state)
