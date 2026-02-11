class_name Smart_Ship
extends Ship

enum State {IDLE, APPROACHING, FLEEING, LATCHING, FLANKING, CIRCLING}
@export var current_state : State
@export var target : Ship
@export var engine_thrust : float
@onready var nav_agent : NavigationAgent2D = $NavigationAgent2D

var piloting : Piloting
var engines : Engines

func _ready() -> void:
	super._ready()
	piloting = get_piloting()
	engines = get_engines()
	current_state = State.IDLE

func _physics_process(_delta: float) -> void:
	pass

## update current_state based on target
func update_state():
	pass

func sit_idle():
	print("bee idling")

func approach_target():
	print("bee approaching")
	var look_dir = nav_agent.get_next_path_position() - piloting.global_position
	var target_angle = look_dir.angle() + PI/2
	var angle_delta = wrapf(target_angle - global_rotation, -PI, PI)
	angular_velocity = angle_delta * engines.rotational_thrust
	linear_velocity -= transform.y * engines.standard_thrust
	
func latch_on(latching_position : Vector2):
	print("bee latching")
	global_position = target.to_global(latching_position)
	var look_dir = -(piloting.global_position - target.global_position)
	rotation = look_dir.angle() + PI/2 + PI

func flee():
	print("bee fleeing")
