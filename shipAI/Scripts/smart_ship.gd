class_name Smart_Ship
extends Ship

# refs
enum _State {IDLE, APPROACHING, ALIGNING, FLEEING, FLANKING, CIRCLING}
@export var current_state : _State
@export var target : Ship
@onready var detection_timer : Timer = $DetectionTimer
@onready var nav_agent : NavigationAgent2D = $NavigationAgent2D
@onready var state_machine : State_Machine = $StateMachine
var piloting : Piloting:
	get:
		return get_piloting()
var origin: Vector2:
	get:
		return piloting.global_position
var engines : Engines:
	get:
		return get_engines()
		
# maffs
var look_dir : Vector2
var _target_angle : float
var _angle_delta : float
var _aligning_speed_scalar : float = 1
var latching_position : Vector2

func _ready() -> void:
	super._ready()
	detection_timer.timeout.connect(ship_detected)
	current_state = _State.IDLE
	#draw_rays(8,700,180,[5])

#region Pathfinding
var safe_vel : Vector2
func ship_detected() -> Ship:
	target = get_tree().get_first_node_in_group("player_ship")
	state_machine.change_state(state_machine.approach_state)
	return target

func distance_from(target_vector : Vector2) -> float:
	return global_position.distance_to(target_vector)

func face_target(target_vector : Vector2, reverse:bool):
	look_dir = target_vector - origin
	_target_angle = look_dir.angle() + PI/2 + (PI if reverse else 0.0)
	_angle_delta = wrapf(_target_angle - global_rotation, -PI, PI)
	var _delta = get_process_delta_time()
	angular_velocity = _angle_delta * engines.rotational_thrust 
	angular_velocity *= engines.power_level * _delta * _aligning_speed_scalar
	
func compute_safe_vel(safe_velocity:Vector2):
	safe_vel = safe_velocity
#endregion

#region State Processes
#func update_state():
	#pass
#func process_state():
	#match current_state:
		#_State.IDLE:
			#sit_idle()
		#_State.APPROACHING:
			#approach_target()
		#_State.ALIGNING:
			#align()
		#_State.FLANKING:
			#flank()
		#_State.FLEEING:
			#flee()

#func sit_idle():
	#print("%s idling" % [name])
	#pass
#
#func approach_target():
	#print("%s approaching" % [name])
	#face_target(target.get_piloting().global_position, false)
	#linear_velocity += look_dir.normalized() * engines.standard_thrust * engines.power_level
	#linear_velocity /= mass
#
#func align():
	#print("%s aligning" % [name])
	#face_target(target.get_piloting().global_position, true)
	#global_position = target.to_global(latching_position)
#
#func flee():
	#print("%s fleeing" % [name])
	#face_target(target.get_piloting().global_position, true)
	#linear_velocity -= look_dir.normalized() * engines.standard_thrust * engines.power_level
	#linear_velocity /= mass
#
#func flank():
	#print("%s flanking" % [name])
	#pass
#endregion 
