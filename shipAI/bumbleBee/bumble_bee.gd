class_name Bumble_Bee
extends Smart_Ship

@onready var detection_timer : Timer = $DetectionTimer
@export var latching_position : Vector2

func _ready() -> void:
	super()
	detection_timer.timeout.connect(ship_detected)

func _physics_process(_delta: float) -> void:
	if not engines or not piloting:
		return
	update_state()

func update_state() -> void:
	if target == null:
		current_state = State.IDLE
	else:
		if nav_agent.is_target_reached():
			if current_state != State.LATCHING:
				latching_position = target.to_local(piloting.global_position)
			current_state = State.LATCHING
		else:
			nav_agent.target_position = target.get_piloting().global_position
			current_state = State.APPROACHING
		
	match current_state:
		State.IDLE:
			sit_idle()
		State.APPROACHING:
			approach_target()
		State.LATCHING:
			latch_on(latching_position)
		State.FLEEING:
			flee()

func _on_detection_range_body_entered(body: Node2D) -> void:
	if body.is_in_group("player_ship"):
		detection_timer.start()
	
func _on_detection_range_body_exited(body: Node2D) -> void:
	if body.is_in_group("player_ship"):
		target = null
		detection_timer.stop()

func ship_detected():
	target = get_tree().get_first_node_in_group("player_ship")
	
