class_name Bumble_Bee
extends Smart_Ship

'''
fly up to target if detected
start shooting
if target starts shooting or at least looking in direction of self
then start fleeing & shooting backwards
'''

@onready var detection_timer : Timer = $DetectionTimer

func _ready() -> void:
	super._ready()
	detection_timer.timeout.connect(ship_detected)

func _physics_process(_delta: float) -> void:
	'''
	update_state()
	move navAgent toward destination
	change behavior based on state
	'''
	pass
	
func update_state() -> void:
	'''
	if no target
		then idle
	elif target
		then approach
	elif target is too close 
		then flee
	elif took dmg
		then flee
	
	switch state
		case idle
		case approach
		case flee
	'''
	pass

func _on_detection_range_body_entered(body: Node2D) -> void:
	if body.is_in_group("player_ship"):
		detection_timer.start()
	
func _on_detection_range_body_exited(body: Node2D) -> void:
	if body.is_in_group("player_ship"):
		target = null
		detection_timer.stop()
		
func ship_detected():
	target = get_tree().get_first_node_in_group("player_ship")
