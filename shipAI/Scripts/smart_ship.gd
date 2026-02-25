class_name Smart_Ship
extends Ship

# refs
@export var target : Ship
@onready var detection_timer : Timer = $DetectionTimer
@onready var nav_agent : NavigationAgent2D = $NavigationAgent2D
@onready var state_machine : State_Machine = $StateMachine
@onready var detection_range : Area2D = $DetectionRange
var piloting : Piloting:
	get:
		return get_piloting()
var origin : Vector2:
	get:
		return get_piloting().global_position
var engines : Engines:
	get:
		return get_engines()
var standard_thrust : int:
	get:
		return engines.standard_thrust * engines.power_level
		
# maffs
var look_dir : Vector2
var _target_angle : float
var _angle_delta : float
var _aligning_speed_scalar : float = 1
var latching_position : Vector2

func _ready() -> void:
	super._ready()
	detection_timer.timeout.connect(ship_detected)

#region Target Detection
func ship_detected():
	target = get_tree().get_first_node_in_group("player_ship")
	state_machine.change_state(state_machine.approach_state)
#endregion

#region Pathfinding
var safe_vel : Vector2
func face_target(target_vector : Vector2, reverse:bool):
	look_dir = target_vector - origin
	_target_angle = look_dir.angle() + PI/2 + (PI if reverse else 0.0)
	_angle_delta = wrapf(_target_angle - global_rotation, -PI, PI)
	var _delta = get_process_delta_time()
	angular_velocity = _angle_delta * engines.rotational_thrust 
	angular_velocity *= engines.power_level * _delta * _aligning_speed_scalar

func cache_safe_vel(safe_velocity:Vector2):
	safe_vel = safe_velocity
#endregion
