class_name State_Machine
extends Node

@export var current_state : State

@export var idle_state : State
@export var approach_state : State
@export var align_state : State
@export var flee_state : State

@onready var auto_pilot : Room = $".."
@onready var nav_agent : NavigationAgent2D = $"../NavigationAgent2D"

func _ready() -> void:
	current_state = idle_state

func _physics_process(delta: float) -> void:
	if current_state:
		current_state.process_state_physics(delta)

func change_state(new_state:State):
	if current_state != null:
		current_state.exit_state()
	current_state = new_state
	current_state.enter_state()
