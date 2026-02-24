class_name State
extends Node

@onready var controller : State_Machine = $".."
var nav_agent : NavigationAgent2D
var target : Ship
var ship : Smart_Ship

func enter_state():
	print(controller.ship.name + " entered " + name)

func exit_state():
	print(controller.ship.name + " exited " + name)
	
func process_state_physics(_delta:float):
	pass
