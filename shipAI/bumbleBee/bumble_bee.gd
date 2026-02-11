class_name Bumble_Bee
extends Smart_Ship

'''
fly up to target if detected
turn away and start shooting
if target starts shooting or at least looking in direction of self
then start fleeing while shooting
'''

@onready var detection_timer : Timer = $DetectionTimer
@onready var combat_range : float

var engines : Engines
var piloting : Piloting

func _ready() -> void:
	super._ready()
	detection_timer.timeout.connect(ship_detected)
	engines = get_engines()
	piloting = get_piloting()

func _physics_process(delta: float) -> void:
	'''
	update_state()
	move navAgent toward destination
	change behavior based on state
	'''
	if not engines or not piloting:
		return

	update_state()

func update_state() -> void:
	# change state
	if target == null:
		current_state = State.IDLE
	else:
		current_state = State.APPROACHING
		# if hp too low || if room is lost then flee TODO
		
	# react to state
	match current_state:
		State.IDLE:
			print("bee idling")
			pass
		State.APPROACHING:
			print("bee approaching")
			nav_agent.target_position = target.global_position
			if not nav_agent.is_navigation_finished():
				var look_dir = nav_agent.get_next_path_position() - piloting.global_position
				#var look_dir = target.global_position - global_position
				var target_angle = look_dir.angle() + PI/2
				var angle_delta = wrapf(target_angle - global_rotation, -PI, PI)
				angular_velocity = angle_delta * engines.rotational_thrust
				linear_velocity -= transform.y * engines.standard_thrust
			else:
				current_state = State.LATCHING
		State.LATCHING:
			print("bee latching")
			# stop moving & lock position relative to player
			# rotate 180
			# repeatedly shoot back cannon $Cannon.gun.shoot()
		State.FLEEING:
			print("bee fleeing")
			# fly forward and kinda fast

func _on_detection_range_body_entered(body: Node2D) -> void:
	if body.is_in_group("player_ship"):
		detection_timer.start()
	
func _on_detection_range_body_exited(body: Node2D) -> void:
	if body.is_in_group("player_ship"):
		target = null
		detection_timer.stop()

func ship_detected():
	target = get_tree().get_first_node_in_group("player_ship")
