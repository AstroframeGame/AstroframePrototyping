class_name State_Machine
extends Node

@export var current_state : State

@export var idle_state : State
@export var approach_state : State
@export var sting_state : State
@export var flee_state : State

@onready var auto_pilot : Room = $".."

func _ready() -> void:
	current_state = idle_state

func state_is_equal(comparison:State):
	if current_state != null:
		return current_state == comparison

func change_state(new_state:State):
	if current_state != null:
		current_state.exit_state()
	current_state = new_state
	current_state.enter_state()
