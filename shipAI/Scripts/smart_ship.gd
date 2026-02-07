class_name Smart_Ship
extends Ship

''' DETECTION
target is in detection if this took dmg
if it is in vision cone
elif it has stayed in range long enough 
'''

enum State {IDLE, APPROACHING, FLEEING, FLANKING, CIRCLING}
@export var current_state : State
@export var target : Ship
@export var engine_thrust : float
@onready var navAgent : NavigationAgent2D = $NavigationAgent2D

func _ready() -> void:
	super._ready()
	current_state = State.IDLE

func _physics_process(_delta: float) -> void:
	pass

## update current_state based on target
func update_state():
	pass
