class_name Autopilot
extends Room

''' TODO:
* draw nav_obstacle on ready
* radius = 220, center on ship.center_of_mass
* draw $DetectionArea centered on ship.center_of_mass
* and radius = 1000 
'''

@onready var state_machine : State_Machine = $StateMachine
@onready var detection_area : Area2D = $DetectionArea
@onready var _detection_shape : CollisionShape2D = $DetectionArea/CollisionShape2D
@onready var nav_agent : NavigationAgent2D = $NavigationAgent2D
@onready var nav_obstacle : NavigationObstacle2D = $NavigationObstacle2D

var goal_velocity : Vector2
var goal_angular_velocity : float

func _ready() -> void:
	if ship:
		nav_obstacle.radius = 220
		_detection_shape.shape.radius = 1000
		detection_area.global_position = ship.to_global(ship.center_of_mass)
		nav_obstacle.global_position = ship.to_global(ship.center_of_mass)

func shoot_all_cannons():
	for child in ship.get_children():
		if child is Cannon:
			child.shoot()

func is_active() -> bool:
	return power_level > 1

func get_goal_velocity(current_velocity: Vector2) -> Vector2:
	var engines = ship.get_engines()
	if not engines:
		return Vector2.ZERO
	
	var goal_vel = current_velocity
	# set this to the goal direction. use current vel to not overshoot
	# dirs/deltas will be normalized. here ↓
	goal_vel = goal_vel.normalized() * min(goal_vel.length(), engines.get_max_speed())
	return goal_vel

func is_idling() -> bool:
	return state_machine.current_state == state_machine.idle_state

func get_goal_angular_velocity() -> float:
	var engines = ship.get_engines()
	if not engines:
		return 0.0
		
	var rot_input = 0.0 # set this to sign(delta rotation) * fun constant
	# def needs to be updated to be normalized, but not now. 
	return rot_input * engines.get_rotational_thrust()
