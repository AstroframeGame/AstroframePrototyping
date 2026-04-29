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
	
		
	state_machine.current_state.process_state_physics(delta)
	
	if state_machine.current_state != state_machine.flee_state:
		if ship and ship.hit_points < float(ship.max_hit_points)/2:
			state_machine.change_state(state_machine.flee_state)

func shoot_all_cannons():
	for cannon in ship.get_cannons():
		cannon.shoot()

#region Getters
func is_active() -> bool:
	return ship and not ship.get_piloting() and power_level == 2

func is_idling() -> bool:
	return state_machine.current_state == state_machine.idle_state

func distance_to_target()->float:
	return ship.get_center().distance_to(target_ship.get_center())
#endregion

#region Movement

#endregion

#region Target Aquisition~

#endregion

#region Avoidance

#endregion
