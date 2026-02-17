class_name Smart_Ship
extends Ship

enum State {IDLE, APPROACHING, ALIGNING, FLEEING, LATCHING, FLANKING, CIRCLING}
@export var current_state : State
@export var target : Ship
@export var engine_thrust : float
@onready var nav_agent : NavigationAgent2D = $NavigationAgent2D
@onready var detection_timer : Timer = $DetectionTimer

var piloting : Piloting
var engines : Engines

var _latching_position : Vector2

func _ready() -> void:
	super._ready()
	piloting = get_piloting()
	engines = get_engines()
	detection_timer.timeout.connect(ship_detected)
	current_state = State.IDLE

func _physics_process(_delta: float) -> void:
	pass

func ship_detected():
	target = get_tree().get_first_node_in_group("player_ship")

func update_state():
	pass
	
#region State Processes
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

func sit_idle():
	print("wasp idling")

func approach_target():
	print("wasp approaching")
	_look_dir = nav_agent.get_next_path_position() - piloting.global_position
	_target_angle = _look_dir.angle() + PI/2
	_angle_delta = wrapf(_target_angle - global_rotation, -PI, PI)
	angular_velocity = _angle_delta * engines.rotational_thrust * PI
	linear_velocity -= transform.y * engines.standard_thrust

func align():
	print("wasp aligning")
	global_position = target.to_global(_latching_position)
	_look_dir = -(piloting.global_position - target.global_position)
	_target_angle = _look_dir.angle() + PI/2 + PI
	_angle_delta = wrapf(_target_angle - rotation, -PI, PI)
	var _delta = get_process_delta_time()
	angular_velocity = _angle_delta * engines.rotational_thrust * _delta * 1000
	
func latch_on():
	print("wasp latching")
	global_position = target.to_global(_latching_position)
	_look_dir = -(piloting.global_position - target.global_position)
	rotation = _look_dir.angle() + PI/2 + PI
	for cannon in get_cannons():
		cannon.gun.shoot(5)

func flank():
	print("")

func flee():
	print("wasp fleeing")
	linear_velocity -= transform.y * engines.standard_thrust * 3
#endregion 
