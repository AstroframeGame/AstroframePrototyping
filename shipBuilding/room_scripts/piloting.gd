class_name Piloting
extends Room

@onready var seat: SeatInteractable = $SeatHex/SeatInteractable

# this method is searched by name from the player
func handle_input(event:InputEvent):
	if event.is_action_pressed("ship_fire"): #See turret.gd for ACTUAL firing
		shoot_all_cannons()
		return
	ship.handle_input(event) #MIGHT BE MOVED
	

func shoot_all_cannons():
	for child in ship.get_children():
		if child is Cannon:
			child.shoot()

func is_active() -> bool:
	return seat.controlled_by != null

func goal_velocity() -> Vector2:
	var engines = ship.get_engines()
	if not engines:
		return Vector2.ZERO
		
	var direction = Input.get_vector("left", "right", "up", "down")
	var goal_vel = Vector2.ZERO
	
	if Input.is_action_pressed("brake"):
		return Vector2.ZERO
	if direction.length() < 0.1:
		# autobrake
		return Vector2.ZERO
		
	goal_vel = ship.linear_velocity + direction.rotated(ship.global_rotation)
	goal_vel = goal_vel.normalized() * min(goal_vel.length(), engines.get_max_speed())
	return goal_vel

func goal_angular_velocity() -> float:
	var engines = ship.get_engines()
	if not engines:
		return 0.0
	return _get_rotation_input() * engines.get_rotational_thrust()

func _get_rotation_input() -> float:
	if InputHelper.using_mouse:
		return InputHelper.mouse_center_offset_deadzone(ship.FLIGHT_DEADZONE).x * 0.01
	return InputHelper.controller_look.x
