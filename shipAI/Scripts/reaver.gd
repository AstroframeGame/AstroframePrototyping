class_name Reaver
extends Smart_Ship

''' TODO:
* flanking behavior
* add a visual indicator for detections
'''

func _ready() -> void:
	super()

func _physics_process(_delta: float) -> void:
	if not engines or not piloting:
		return
	update_state()
	process_state()
		
	
'''
idle
when target then approach
when close then flank
then latch
when low hp then flee
'''
func update_state():
	if target == null:
		current_state = State.IDLE
	else:
		if distance_to_target() < 600:
			if current_state != State.FLANKING:
				pass
		else:
			current_state = State.APPROACHING
