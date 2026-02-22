class_name Smart_Ship
extends Ship

enum State {IDLE, APPROACHING, ALIGNING, FLEEING, LATCHING, FLANKING, CIRCLING}
@export var current_state : State
@export var target : Ship
@onready var detection_timer : Timer = $DetectionTimer
@onready var raycast : RayCast2D = $RayCast2D

var piloting : Piloting
var engines : Engines

func _ready() -> void:
	super._ready()
	piloting = get_piloting()
	engines = get_engines()
	detection_timer.timeout.connect(ship_detected)
	current_state = State.IDLE

func _physics_process(_delta: float) -> void:
	pass

#region Target Processing
func ship_detected() -> Ship:
	target = get_tree().get_first_node_in_group("player_ship")
	return target

func distance_to_target() -> float:
	return global_position.distance_to(target.global_position)
#endregion
	
#region State Processes
func update_state():
	pass

func process_state():
	match current_state:
		State.IDLE:
			sit_idle()
		State.APPROACHING:
			approach_target()
		State.ALIGNING:
			align()
		State.LATCHING:
			latch_on()
		State.FLANKING:
			flank()
		State.FLEEING:
			flee()

var _look_dir : Vector2
var _target_angle : float
var _angle_delta : float
@warning_ignore("unused_private_class_variable")
var _latching_position : Vector2
@onready var _aligning_speed_scalar : int = 1


func sit_idle():
	print("%s idling" % [name])
	pass

func approach_target():
	print("%s approaching" % [name])
	# TODO: avoidance
	# raycast to get obstacles
	raycast.target_position = to_local(target.global_position)
	if raycast.is_colliding():
		if not raycast.get_collider().is_in_group("player_ship"):
			pass
	# face target
	_look_dir = target.get_piloting().global_position - piloting.global_position
	_target_angle = _look_dir.angle() + PI/2
	_angle_delta = wrapf(_target_angle - global_rotation, -PI, PI)
	var _delta = get_process_delta_time()
	angular_velocity = _angle_delta * engines.rotational_thrust 
	angular_velocity *= engines.power_level * _delta * _aligning_speed_scalar
	# move
	linear_velocity += _look_dir.normalized() * engines.standard_thrust * engines.power_level
	linear_velocity /= mass

func align():
	print("%s aligning" % [name])
	# point butt at target
	_look_dir = -(piloting.global_position - _latching_position)
	_target_angle = _look_dir.angle() + PI/2 + PI
	_angle_delta = wrapf(_target_angle - global_rotation, -PI, PI)
	var _delta = get_process_delta_time()
	angular_velocity = _angle_delta * engines.rotational_thrust 
	angular_velocity *= engines.power_level * _delta * _aligning_speed_scalar
	# lock relative position
	linear_velocity = (target.to_local(piloting.global_position) - _latching_position)
	linear_velocity *= engines.standard_thrust * engines.power_level
	linear_velocity /= mass
	
func latch_on():
	print("%s latching" % [name])
	# lock relative position
	global_position = target.to_global(_latching_position)
	# lock rotation
	_look_dir = -(piloting.global_position - target.global_position)
	rotation = _look_dir.angle() + PI/2 + PI
	for cannon in get_cannons():
		cannon.gun.shoot(5)

func flank():
	print("%s flanking" % [name])
	pass

func flee():
	print("%s fleeing" % [name])
	_look_dir = -(piloting.global_position - target.global_position)
	_target_angle = _look_dir.angle() + PI/2
	_angle_delta = wrapf(_target_angle - global_rotation, -PI, PI)
	var _delta = get_process_delta_time()
	angular_velocity = _angle_delta * engines.rotational_thrust 
	angular_velocity *= engines.power_level * _delta * _aligning_speed_scalar
	# move
	linear_velocity += _look_dir.normalized() * engines.standard_thrust * engines.power_level
	linear_velocity /= mass
	
#endregion 
