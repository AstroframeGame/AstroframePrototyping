class_name Bucaneer
extends Smart_Ship

''' TODO:
* flanking behavior
* 
'''

func _ready() -> void:
	super()

func _physics_process(_delta: float) -> void:
	if not engines or not piloting:
		return
		
	
func update_state():
	if target == null:
		current_state = State.IDLE
	else:
		if nav_agent.is_target_reached():
			if current_state != State.FLANKING:
				# navigate to the side of the player's ship
				pass
		else:
			nav_agent.target_position = target.get_piloting().global_position
			current_state = State.APPROACHING
