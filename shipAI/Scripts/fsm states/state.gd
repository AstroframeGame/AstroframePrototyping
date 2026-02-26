class_name State
extends Node

@onready var controller : State_Machine = $".."
var auto_pilot : Autopilot
var nav_agent : NavigationAgent2D
var target_ship : Ship
var ship : Ship

func enter_state():
	auto_pilot = controller.auto_pilot
	nav_agent = auto_pilot.nav_agent
	target_ship = auto_pilot.target_ship
	ship = auto_pilot.ship
	print(ship.name + " entered " + name)

func exit_state():
	if ship:
		print(ship.name + " exited " + name)
	
func process_state_physics(_delta:float):
	pass
