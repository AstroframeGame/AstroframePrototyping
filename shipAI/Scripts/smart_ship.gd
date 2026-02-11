class_name Smart_Ship
extends Ship

enum State {IDLE, APPROACHING, FLEEING, LATCHING, FLANKING, CIRCLING}
@export var current_state : State
@export var target : Ship
@export var engine_thrust : float
@onready var nav_agent : NavigationAgent2D = $NavigationAgent2D

func _ready() -> void:
	super._ready()
	current_state = State.IDLE

func _physics_process(_delta: float) -> void:
	pass

## update current_state based on target
func update_state():
	pass
