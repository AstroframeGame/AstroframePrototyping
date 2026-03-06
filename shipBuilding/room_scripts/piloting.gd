class_name Piloting
extends Room

@onready var seat: SeatInteractable = $SeatHex
var THRUST_LOOP = preload("res://audio/sfx/SfxAudioFileFolder/engine_loop.wav")

# this method is searched by name from the player
func handle_input(event:InputEvent):
	if event.is_action_pressed("ship_fire"): #See turret.gd for ACTUAL firing
		shoot_all_cannons()
		return
	
func shoot_all_cannons():
	for child in ship.get_children():
		if child is Cannon:
			child.shoot()

func is_active() -> bool:
	return seat.controlled_by != null

func get_goal_velocity(current_velocity: Vector2) -> Vector2:
	var engines = ship.get_engines()
	if not engines:
		return Vector2.ZERO
		
	var direction = Input.get_vector("left", "right", "up", "down")
	
	if Input.is_action_pressed("up"):
		if !sfx.playing && ship.linear_velocity.length() > 170.0:
				print(ship.linear_velocity.length())
				sfx.play()
				play_sfx(THRUST_LOOP)
	
	if Input.is_action_pressed("brake"):
		sfx.stop()
		return Vector2.ZERO
	
	if Input.is_action_just_released("up"):
		sfx.stop()
		
	var goal_vel = Vector2.ZERO
	if direction.length() > 0.1:
		if direction.y < 0:
			direction.y *= engines.forward_multiplier

		goal_vel = current_velocity + direction.rotated(ship.global_rotation)
		goal_vel = goal_vel.normalized() * min(goal_vel.length(), engines.get_max_speed())
	return goal_vel

func is_idling() -> bool:
	var direction = Input.get_vector("left", "right", "up", "down")
	return direction.length() <= 0.1 and not Input.is_action_pressed("brake")

func get_goal_angular_velocity() -> float:
	var engines = ship.get_engines()
	if not engines:
		return 0.0
		
	var rot_input = InputHelper.controller_look.x
	if InputHelper.using_mouse:
		rot_input = InputHelper.mouse_center_offset_deadzone(ship.FLIGHT_DEADZONE).x * 0.01
		
	return rot_input * engines.get_rotational_thrust()

@onready var sfx: AudioStreamPlayer2D = $ThrustSFX

func play_sfx(sound: AudioStream):
	var polyphonic : AudioStreamPlaybackPolyphonic = sfx.get_stream_playback() as AudioStreamPlaybackPolyphonic
	polyphonic.play_stream(sound, 0,0,1, AudioServer.PLAYBACK_TYPE_DEFAULT, "SFX")
	
