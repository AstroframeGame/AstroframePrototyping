extends State

var target : Ship
var ship : Smart_Ship
var nav_agent : NavigationAgent2D

func enter_state():
	super()
	target = controller.ship.target
	ship = controller.ship
	nav_agent = controller.nav_agent
	nav_agent.target_position = target.get_piloting().global_position

func process_state_physics(_delta:float):
	if not nav_agent.is_navigation_finished():
		nav_agent.target_position = target.get_piloting().global_position
		var path_point = nav_agent.get_next_path_position()
		var path_dir = -(ship.piloting.global_position - path_point)
		ship.face_target(path_point, false)
		ship.linear_velocity = path_dir.normalized()
		ship.linear_velocity *= ship.engines.standard_thrust * ship.engines.power_level
		ship.linear_velocity /= ship.mass
	
func exit_state():
	ship.latching_position = target.to_local(ship.piloting.global_position)
