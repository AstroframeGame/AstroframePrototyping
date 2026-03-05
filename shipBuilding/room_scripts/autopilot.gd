class_name Autopilot
extends Room

@onready var state_machine : State_Machine = $StateMachine
@onready var detection_area : Area2D = $DetectionArea
@onready var _detection_shape : CollisionShape2D = $DetectionArea/CollisionShape2D
@onready var detection_timer : Timer = $DetectionTimer
@onready var nav_agent : NavigationAgent2D = $NavigationAgent2D
@onready var nav_obstacle : NavigationObstacle2D = $NavigationObstacle2D

var target_ship : Ship

var movement_goal_direction : Vector2
## goal rotation in radians
var rotation_goal : float
var safe_vel : Vector2
var latching_position : Vector2

func _ready() -> void:
	super()
	detection_area.body_entered.connect(on_body_entered,1)
	detection_area.body_exited.connect(on_body_exited,1)
	detection_timer.timeout.connect(on_player_ship_detected)
	nav_agent.navigation_finished.connect(on_navigation_finished)
	on_power_level_change.connect(on_power_change,1)
	
	# TODO: these need to be based on ship size
	nav_obstacle.radius = 220
	nav_agent.radius = 220
	_detection_shape.shape.radius = 1500
	
	if ship:
		if ship.has_engines():
			nav_agent.max_speed = ship.get_engines().max_speed
		if ship.hit_points > 0:
			ship.pair_all_links()
			
		detection_area.global_position = ship.get_center()
		nav_obstacle.global_position = ship.get_center()
	#draw_rays(8,1500,180)

func _physics_process(delta: float) -> void:
	if not is_instance_valid(state_machine):
		return
	if not state_machine.current_state:
		return
	if not is_active():
		clear_targetting()
		return
		
	state_machine.current_state.process_state_physics(delta)
	
	if state_machine.current_state != state_machine.flee_state:
		if ship and ship.hit_points < float(ship.max_hit_points)/2:
			state_machine.change_state(state_machine.flee_state)

func shoot_all_cannons():
	for cannon in ship.get_cannons():
		cannon.shoot()

#region Getters
func is_active() -> bool:
	return not ship.get_piloting() and power_level == 2

func is_idling() -> bool:
	return state_machine.current_state == state_machine.idle_state

func distance_to_target()->float:
	return ship.get_center().distance_to(target_ship.get_center())
#endregion

#region Movement
func get_goal_velocity(current_velocity: Vector2) -> Vector2:
	var engines = ship.get_engines()
	if not engines:
		return Vector2.ZERO

	var goal_vel = Vector2.ZERO
	goal_vel = current_velocity + movement_goal_direction
	goal_vel = goal_vel.normalized() * min(goal_vel.length(), engines.get_max_speed())
	return goal_vel

func get_goal_angular_velocity() -> float:
	if not ship.has_engines():
		return 0.0
	if not target_ship:
		return 0.0

	var delta_rotation = rotation_goal - ship.global_rotation
	
	var rot_input = sign(delta_rotation)
	
	return rot_input * ship.get_rotational_thrust()

func on_navigation_finished():
	if not is_active():
		return
		
	if ship.has_engines():
		state_machine.change_state(state_machine.sting_state)
#endregion

#region Target Aquisition~
var target_candidate : Ship
func on_body_entered(body):
	if not is_active():
		return
	if body is Ship and body.is_in_group("player_ship"):
		target_candidate = body
		detection_timer.start()
		
func on_body_exited(body):
	if not is_active():
		return
	if not is_instance_valid(body):
		return
	if body.is_in_group("player_ship"):
		target_ship = null
		detection_timer.stop()
		if ship.has_engines():
			state_machine.change_state(state_machine.idle_state)
	if body == target_candidate:
		target_candidate = null
		
func on_player_ship_detected():
	if not is_active():
		return
	target_ship = target_candidate
	target_candidate = null
	if ship.has_engines():
		state_machine.change_state(state_machine.approach_state)

func on_power_change(_room):
	if not is_active():
		clear_targetting()
		return
	for body : Node2D in detection_area.get_overlapping_bodies():
		if body.is_in_group("player_ship"):
			target_candidate = body
			detection_timer.start()

func clear_targetting():
	target_candidate = null
	target_ship = null
	movement_goal_direction = Vector2.ZERO
	rotation_goal = rotation
	state_machine.change_state(state_machine.idle_state)

#endregion

#region Avoidance
var rays : Array[RayCast2D] = []

func draw_rays(amount:int, length:float, fan_angle:float):
	if ship == null:
		return
	var step_angle = fan_angle / (amount-1)
	var start_angle = -(fan_angle-global_rotation_degrees)/2 + 90
	
	for i in range(amount):
		var ray = RayCast2D.new()
		add_child(ray)
		var angle = deg_to_rad(start_angle + (i*step_angle))
		ray.target_position = Vector2(cos(angle), sin(angle)) * length
		ray.global_position = ship.get_center()
		ray.add_exception(ship)
		ray.collision_mask = ship.collision_mask
		rays.append(ray)

func get_ray_collisions()->Array[Node2D]:
	var collisions : Array[Node2D]
	if ship == null:
		return collisions
	for ray in rays:
		if ray.is_colliding():
			collisions.append(ray.get_collider())
	return collisions
#endregion
