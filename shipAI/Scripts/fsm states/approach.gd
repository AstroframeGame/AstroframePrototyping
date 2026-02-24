extends State

var target : Ship
var ship : Smart_Ship

func enter_state():
	super()
	target = controller.ship.target
	ship = controller.ship
	controller.nav_agent.target_position = target.global_position

func process_state_physics(_delta:float):
	ship.face_target(target.global_position, false)
	ship.linear_velocity = ship.look_dir.normalized()
	ship.linear_velocity *= ship.engines.standard_thrust * ship.engines.power_level
	ship.linear_velocity /= ship.mass
	
func exit_state():
	ship.latching_position = target.to_local(ship.piloting.global_position)
