extends State

var target : Ship
var ship : Smart_Ship

func enter_state():
	super()
	ship = controller.ship
	target = ship.target

func process_state_physics(_delta:float):
	ship.face_target(target.get_piloting().global_position, true)
	ship.linear_velocity -= ship.look_dir.normalized() 
	ship.linear_velocity *= ship.engines.standard_thrust * ship.engines.power_level
	ship.linear_velocity /= ship.mass
