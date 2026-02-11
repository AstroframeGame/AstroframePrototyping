class_name Bumble_Bee
extends Smart_Ship

'''
fly up to target if detected
turn away and start shooting
if target starts shooting or at least looking in direction of self
then start fleeing while shooting
'''

@onready var detection_timer : Timer = $DetectionTimer
## position relative to target when "latching"
@export var latching_position : Vector2

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
	if target == null:
		current_state = State.IDLE
	else:
		if nav_agent.is_target_reached():
			# grab position relative to target -> latching_position
			if current_state != State.LATCHING:
				latching_position = target.to_local(global_position)
			current_state = State.LATCHING
		else:
			nav_agent.target_position = target.global_position
			current_state = State.APPROACHING
		# if hp too low || if room is lost then flee TODO
		
	# react to state
	match current_state:
		State.IDLE:
			print("bee idling")
		State.APPROACHING:
			print("bee approaching")
			if not nav_agent.is_navigation_finished():
				var look_dir = nav_agent.get_next_path_position() - piloting.global_position
				var target_angle = look_dir.angle() + PI/2
				var angle_delta = wrapf(target_angle - global_rotation, -PI, PI)
				angular_velocity = angle_delta * engines.rotational_thrust
				linear_velocity -= transform.y * engines.standard_thrust
		State.LATCHING:
			print("bee latching")
			# stop moving & lock position relative to player 
			global_position = target.to_global(latching_position)
			# point ass to player
				# get position relative to self opposite of player
			var look_dir = -(piloting.global_position - target.global_position)
			#var target_angle = look_dir.angle() + PI/2
			rotation = look_dir.angle() + PI/2 + PI
				# ship.rotate_ship toward it
				
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
	
