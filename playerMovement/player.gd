class_name PlayerCharacter
extends CharacterBody2D

'''
This controls player movement. Configure the controls in Project Settings > Input

WASD to walk around on ground
WASD to thrust when off ground, SPACE to brake

The way that the player checks if it is grounded is with an area, this checks if
the player is over ground, hence whether to use air movement or ground movement
'''

@export var walk_speed = 200
@export var thrust_move = 6
@export var thrust_accel = 800
@export var rotate_speed = 10

@export_flags_2d_physics var interior_layer
@export_flags_2d_physics var interior_mask
@export_flags_2d_physics var exterior_layer
@export_flags_2d_physics var exterior_mask
@export_flags_2d_physics var interior_ground_mask
@export_flags_2d_physics var exterior_ground_mask

# sync these
var pushing #set in physics process
var push_dir
var push_brake

var _seat : SeatInteractable = null
var seat : SeatInteractable :
	get:
		return _seat
	set(value):
		_seat = value
		if value:
			CursorManager.set_cursor_aim()# this should be tied to its own event? maybe this is fine
		else:
			CursorManager.reset_cursor()

# for fake parenting
# separated from ship
var ground_body : PhysicsBody2D
var prev_ground_body_transform : Transform2D

var ship : Ship

@onready var ground_check: Area2D = $GroundCheck
@onready var interact_check: Area2D = $InteractCheck
@onready var multiplayer_manager : MultiplayerManager = $"../.."

@onready var grapple: Grapple = $Grapple

var health = 100

var grounded : bool:
	get:
		ground_check = $GroundCheck
		return ground_check.has_overlapping_bodies() or ground_check.has_overlapping_areas()


@onready var handgun: PlayerGun = $handgun

#region MultiplayerGlobals
## ====== Multiplayer START ======
var is_multiplayer: bool = false
var is_local_player: bool = false

var owner_id: int
var target_vel := Vector2.ZERO
var target_pos := Vector2.ZERO

var input_dir := Vector2.ZERO
var mouse_pos := Vector2.ZERO
var ship_pushed: bool = false
var is_shooting: bool = false
var is_holstering: bool = false
var was_holstering: bool = false
var is_interacting: bool = false
var was_interacting: bool = false
var event_in_room: InputEvent = null
## ======  Multiplayer END  ======
#endregion

#region ReadyFunction
func _ready() -> void:
	ground_check.body_entered.connect(on_ground)
	ground_check.body_exited.connect(on_unground)
	ground_check.area_entered.connect(on_ground)
	ground_check.area_exited.connect(on_unground)
	
	## ====== Multiplayer START ======

	if multiplayer.has_multiplayer_peer():
		is_multiplayer = true
		owner_id = name.to_int()
		target_pos = global_position

		await get_tree().process_frame

		if has_node("MultiplayerSynchronizer"):
			$MultiplayerSynchronizer.set_multiplayer_authority(1)

		if has_node("Grapple"):
			$Grapple.set_multiplayer_authority(1)

		print("Initializing player ", name, " in Multiplayer...")
		print("   Player ", owner_id, 
		" | Local ID: ", multiplayer.get_unique_id(), 
		" | Authority: ", get_multiplayer_authority())
	else:
		$NamerTag.text = ""
		print("Initializing player in Singleplayer")

	## ======  Multiplayer END  ======
	
	if ship:
		on_ship_enter(ship)
	else:
		on_ship_exit()
#endregion

func _physics_process(delta):
	if is_multiplayer_authority():
		apply_ground_body_transform()
		input_dir = input_dir.normalized().rotated(global_rotation)
		if ship_pushed: ## Action for movement
			if pushing:
				pushing = false
			else:
				pushing = ground_body != null and ground_body is Ship and ship == null
		push_dir = input_dir
		#print(ground_body != null , ground_body is Ship , ship == null , Input.is_action_pressed("ship_push"))
		
		if seat or pushing:
			velocity = Vector2.ZERO # ship vel added later
			handgun.holster()
		elif grapple.wants_grapple():
			velocity = grapple.velocity(delta)
		elif grounded:
			# remove rotation?
			#rotate(Input.get_axis("rotate_left","rotate_right") * rotate_speed * delta)
			velocity = input_dir * walk_speed
		else:
			ground_body = null
			var goal_vel = Vector2.ZERO
			if push_brake:
				velocity = velocity.move_toward(Vector2.ZERO, thrust_accel * delta)
			else:
				goal_vel = velocity + input_dir * thrust_move
				velocity = velocity.move_toward(goal_vel, thrust_accel * delta)
		
		if is_shooting:
			sync_shooting.rpc()
		
		if is_holstering and not seat and not was_holstering:
			sync_holstering.rpc()
			was_holstering = true
		elif not is_holstering and was_holstering:
			was_holstering = false
			
		if is_interacting and not was_interacting:
			sync_interacting.rpc()
			was_interacting = true
		elif not is_interacting and was_interacting:
			was_interacting = false
			
		if event_in_room != null and not is_interacting:
			sync_room_inputs.rpc(event_in_room)
		
		for i in range(get_slide_collision_count()):
			var collision = get_slide_collision(i)
			var collider = collision.get_collider()

			if collider is RigidBody2D:
				var force_dir = -collision.get_normal()
				var impulse = force_dir * 200 * delta
				collider.apply_central_impulse(impulse)
		
		sync_state.rpc(global_position, velocity, mouse_pos)
		move_and_slide()
	else:
		global_position = global_position.lerp(target_pos, 0.25)
		velocity = target_vel

## ====== Multiplayer START ======	

func _process(_delta: float) -> void:
	is_local_player = multiplayer.get_unique_id() == owner_id or not is_multiplayer
	
	visible = ship == multiplayer_manager.my_player.ship
	
	if is_local_player:
		var dir = Input.get_vector("left", "right", "up", "down")
		var is_braking = Input.is_action_pressed("brake")
		var pushed = Input.is_action_just_pressed("ship_push")
		var m_pos = get_global_mouse_position()

		if is_multiplayer_authority():
			input_dir   = dir
			push_brake  = is_braking
			ship_pushed = pushed
			mouse_pos   = m_pos
		else:
			send_input.rpc_id(1, dir, m_pos, is_braking, pushed)

#region SyncingMovement
@rpc("any_peer", "call_remote", "reliable")
func send_input(dir: Vector2, m_pos: Vector2, is_braking: bool, pushed: bool):
	var sender_id = multiplayer.get_remote_sender_id()
	if sender_id != owner_id:
		push_warning("Player %d tried to control player %d" % [sender_id, owner_id])
		return

	input_dir   = dir
	push_brake  = is_braking
	ship_pushed = pushed
	mouse_pos   = m_pos

@rpc("authority", "call_remote", "unreliable")
func sync_state(pos: Vector2, vel: Vector2, m_pos: Vector2):
	if not is_multiplayer_authority():
		target_pos = pos
		target_vel = vel
		mouse_pos = m_pos
		
#endregion
#region SyncingActions
@rpc("authority", "call_local", "unreliable")
func sync_shooting():
	handgun.shoot_bullet()

@rpc("authority", "call_local", "unreliable")
func sync_holstering():
	handgun.toggle_holster()


@rpc("authority", "call_local", "unreliable")
func sync_interacting():
	interact()

@rpc("authority", "call_local", "unreliable")
func sync_room_inputs(room_event: InputEvent):
	seat.room.handle_input(room_event)
#endregion

## ======  Multiplayer END  ======

#region InteractionManager
# currently interacts with the first overlapping interactable area, but this can be changed to nearest, last, all, ect.
func interact():
	var interactable = get_interactable()
	if interactable:
		interactable.interact(self)
		print_debug("[", multiplayer.get_unique_id(), "]: ", name, " interacted with ", interactable)
			
func get_interactable() -> Node2D:
	for area in interact_check.get_overlapping_areas():
		if area.has_method("interact"):
			return area
	return null

func get_interactable_hint() -> String:
	var interactable = get_interactable()
	if interactable:
		if interactable.has_method("interact_hint"):
			return interactable.interact_hint()
		return "Press [E] to interact with " + interactable.name
	return ""
#endregion

#region UnhandledInputs
func _unhandled_input(event: InputEvent) -> void:
	if is_local_player:
		var shooting = false
		var holstered = false
		var room_input = null
		var interacting = false
		
		if event.is_action_pressed("player_shoot"):
			shooting = true
			
		if event.is_action_pressed("holster_handgun"):
			if seat:
				return
			holstered = true
	
		if event.is_action_pressed("interact"):
			interacting = true
			
		if seat and seat.room.has_method("handle_input"):
			room_input = event
			
		if is_multiplayer_authority():
			is_shooting    = shooting
			is_holstering   = holstered
			event_in_room  = room_input
			is_interacting = interacting
		else:
			send_unhandled_inputs.rpc_id(1, shooting, holstered, interacting, room_input)
	
@rpc("any_peer", "call_remote", "unreliable")
func send_unhandled_inputs(shooting: bool, holstered: bool, interacting: bool, room_input: InputEvent):
	var sender_id = multiplayer.get_remote_sender_id()
	if sender_id != owner_id:
		push_warning("Player %d tried to control player %d" % [sender_id, owner_id])
		return
	
	is_shooting    = shooting
	is_holstering   = holstered
	is_interacting = interacting
	event_in_room  = room_input
#endregion	
	
#region grounding
# called when ground check intersects with rb
func on_ground(_body : Node2D):
	# maybe chekc if there is more priority for the new ground. ships should be easier to ground than envs
	#print("on_ground ", _body)
	if _body is Area2D:
		#print("parent is ship ", _body.get_parent() is Ship)
		if _body.get_parent() is Ship:
			ground_body = _body.get_parent()
			prev_ground_body_transform = ground_body.global_transform
	elif _body is PhysicsBody2D:
		ground_body = _body
		prev_ground_body_transform = ground_body.global_transform
	#print("gb ",ground_body)

func on_unground(_body : Node2D):
	#print("on_unground ", _body)
	if _body == ground_body:
		ground_body = null

# if you do not know if grounded (like after placing room)
func fix_unsure_grounding():
	ground_body = null
	on_ship_exit()
	for b in ground_check.get_overlapping_bodies():
		on_ground(b)
	for a in ground_check.get_overlapping_areas():
		on_ground(a)

# called when enter airlock
func on_ship_enter(new_ship : Ship):
	on_ground(new_ship)
	ship = new_ship
	new_ship.player = self
	#print(name + " parent to ship")
	update_layers(true)
	

func on_ship_exit():
	# unground will be called when stops intersecting
	#print(name + " parent to wordl")
	if ship:
		ship.player = null
	ship = null
	update_layers(false)

func apply_ground_body_transform():
	if is_instance_valid(ground_body):
		var current_transform = ground_body.global_transform
		var diff = current_transform * prev_ground_body_transform.affine_inverse()
		global_transform = diff * global_transform
		prev_ground_body_transform = current_transform
		
func update_layers(inside : bool):
	if inside:
		collision_layer = interior_layer
		collision_mask = interior_mask
		ground_check.collision_mask = interior_ground_mask
		z_index = 4
	else:
		collision_layer = exterior_layer
		collision_mask = exterior_mask
		ground_check.collision_mask = exterior_ground_mask
		z_index = 12
#endregion

func take_damage(damage : int):
	health -= damage
	print("Damage Taken! Player now at %s health" % health)
	
