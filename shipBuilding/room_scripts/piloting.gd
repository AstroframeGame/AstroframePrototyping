class_name Piloting
extends Room

@onready var seat: SeatInteractable = $SeatHex

#region MultiplayerGlobals&Ready

var input_dir := Vector2.ZERO
var is_braking: bool = false

func _ready() -> void:
	if multiplayer.has_multiplayer_peer():
		await get_tree().process_frame
		set_multiplayer_authority(1)

#endregion

# this method is searched by name from the player
func handle_input(event:StringName):
	if not ship or not ship.driver:
		return
	if ship.driver.is_local_player:
		var fire_bullet = event == "ship_fire" #See turret.gd for ACTUAL firing
		
		if fire_bullet:
			if is_multiplayer_authority():
				shoot_all_cannons()
			else:
				send_shots.rpc_id(1)
		
		
@rpc("any_peer", "call_remote", "reliable")
func send_shots():
	var sender_id = multiplayer.get_remote_sender_id()
	var driver_id = ship.driver.owner_id
	if sender_id != driver_id:
		push_warning("[piloting.gd]: Player %d tried to control player %d" % [sender_id, driver_id])
		return
		
	shoot_all_cannons()

func shoot_all_cannons():
	for child in ship.get_children():
		if child is Cannon:
			child.shoot()

func is_active() -> bool:
	return seat.controlled_by != null

func get_goal_velocity(current_velocity: Vector2) -> Vector2:
	if is_multiplayer_authority():
		var engines = ship.get_engines()
		if not engines:
			return Vector2.ZERO
			
		var direction = input_dir
		var goal_vel = Vector2.ZERO
		
		if !is_braking:
			if direction.length() > 0.1:
				if direction.y > 0:
					direction.y *= engines.forward_multiplier
				goal_vel = current_velocity + direction.rotated(ship.global_rotation)
				goal_vel = goal_vel.normalized() * min(goal_vel.length(), engines.get_max_speed())
		return goal_vel
	else:
		push_warning("[piloting.gd]: Client trying to control target velocity")
		return Vector2.ZERO

#region MultiplayerProcessing
func _process(delta: float) -> void:
	if not seat or not seat.controlled_by:
		return
	if not ship or not ship.players:
		return
	
	var is_local_player = seat.controlled_by.is_local_player
	if is_local_player:
		var dir = Input.get_vector("left", "right", "up", "down")
		var braking = Input.is_action_pressed("brake")
		
		if is_multiplayer_authority():
			input_dir = dir
			is_braking = braking
		else:
			send_input.rpc_id(1, dir, braking)
				
@rpc("any_peer", "call_remote", "unreliable")
func send_input(dir: Vector2, braking: bool):
	var sender_id = multiplayer.get_remote_sender_id()
	var driver_id = null
	if seat and seat.controlled_by:
		driver_id = seat.controlled_by.owner_id	
		if sender_id != driver_id:
			push_warning("[piloting.gd]: Player %d tried to control player %d" % [sender_id, driver_id])
			return
	else:
		push_warning("[piloting.gd]: Seat or Player in Seat are null")
		return

	input_dir = dir
	is_braking = braking
#endregion

func is_idling() -> bool:
	var direction = Input.get_vector("left", "right", "up", "down")
	return direction.length() <= 0.1 and not Input.is_action_pressed("brake")

func get_goal_angular_velocity() -> float:
	if is_multiplayer_authority():
		var engines = ship.get_engines()
		if not engines:
			return 0.0
			
		var rot_input = InputHelper.controller_look.x
		if InputHelper.using_mouse:
			rot_input = InputHelper.mouse_center_offset_deadzone(ship.driver, ship.FLIGHT_DEADZONE).x * 0.01
			
		return rot_input * engines.get_rotational_thrust()
	else:
		push_warning("[piloting.gd]: Client trying to control angular velocity")
		return 0.0

#region PlayerSat
func player_sit_interact(seated_player: PlayerCharacter):
	ship.driver = seated_player
	print("[piloting.gd]: Player sat on pilot seat")


func player_getup_interact():
	ship.driver = null
	print("[piloting.gd]: Player got up from pilot seat")
#endregion
