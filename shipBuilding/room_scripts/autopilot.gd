class_name Autopilot
extends Room

@onready var state_machine : State_Machine = $StateMachine
@onready var detection_area : Area2D = $DetectionArea
@onready var _detection_shape : CollisionShape2D = $DetectionArea/CollisionShape2D
@onready var detection_timer : Timer = $DetectionTimer
@onready var nav_agent : NavigationAgent2D = $NavigationAgent2D
@onready var nav_obstacle : NavigationObstacle2D = $NavigationObstacle2D

var target_ship : Ship

func _ready() -> void:
	detection_area.body_entered.connect(on_body_entered,1)
	detection_area.body_exited.connect(on_body_exited,1)
	detection_timer.timeout.connect(on_player_detected)
	nav_agent.velocity_computed.connect(on_safe_vel_computed,1)
	nav_agent.navigation_finished.connect(on_navigation_finished)
	
	# TODO: these need to be based on ship size
	nav_obstacle.radius = 220
	nav_agent.radius = 220
	_detection_shape.shape.radius = 1500
	
	if ship:
		if ship.get_engines():
			nav_agent.max_speed = ship.get_engines().max_speed
		detection_area.global_position = ship.get_center()
		nav_obstacle.global_position = ship.get_center()

func shoot_all_cannons():
	for cannon in ship.get_cannons():
		cannon.shoot()

#region Getters
func is_active() -> bool:
	return power_level > 1

func is_idling() -> bool:
	return state_machine.current_state == state_machine.idle_state

func distance_to_target()->float:
	return ship.get_center().distance_to(target_ship.get_center())
#endregion

#region Movement
var movement_goal_direction : Vector2
var rotation_goal_direction : float
var safe_vel : Vector2
var latching_position : Vector2

func get_goal_velocity(current_velocity: Vector2) -> Vector2:
	var engines = ship.get_engines()
	if not engines:
		return Vector2.ZERO
	
	var goal_vel = Vector2.ZERO
	#goal_vel = current_velocity + movement_goal_direction.rotated(ship.global_rotation) #+ safe_vel
	goal_vel = current_velocity + movement_goal_direction
	goal_vel = goal_vel.normalized() * min(goal_vel.length(), engines.get_max_speed())
	return goal_vel

# clamp this to +/- 100
func get_goal_angular_velocity() -> float:
	var engines = ship.get_engines()
	if not engines:
		return 0.0
	if not target_ship:
		return 0.0
		
	#var goal_rotation = (ship.get_center() - target_ship.get_center()).angle() - PI/2
	#var delta_rotation = goal_rotation - ship.global_rotation
	var delta_rotation = rotation_goal_direction - ship.global_rotation
	
	var rot_input = sign(delta_rotation)
	return rot_input * engines.get_rotational_thrust()


func on_safe_vel_computed(safe_velocity:Vector2):
	safe_vel = safe_velocity
	if state_machine.current_state:
		state_machine.current_state.process_state_physics(0.0)
	# hijacking this for tick-ly updates
	if ship.hit_points < float(ship.max_hit_points)/2 and state_machine.current_state != state_machine.flee_state:
		state_machine.change_state(state_machine.flee_state)

func on_navigation_finished():
	state_machine.change_state(state_machine.sting_state)
#endregion

#region Player Detection
var target_candidate : Ship
func on_body_entered(body:Node2D):
	if body.is_in_group("player_ship"):
		target_candidate = body
		detection_timer.start()
		
func on_body_exited(body:Node2D):
	if body.is_in_group("player_ship"):
		target_ship = null
		detection_timer.stop()
		state_machine.change_state(state_machine.idle_state)
	if body == target_candidate:
		target_candidate = null
		
func on_player_detected():
	target_ship = target_candidate
	target_candidate = null
	state_machine.change_state(state_machine.approach_state)

#endregion
