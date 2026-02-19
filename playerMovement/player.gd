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
@export var thrust_accel = 400
@export var rotate_speed = 10

@export_flags_2d_physics var interior_layer
@export_flags_2d_physics var interior_mask
@export_flags_2d_physics var exterior_layer
@export_flags_2d_physics var exterior_mask

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
var ground_body : RigidBody2D
var prev_ground_body_transform : Transform2D

var ship : Ship

@onready var ground_check: Area2D = $GroundCheck
@onready var interact_check: Area2D = $InteractCheck

@onready var grapple: Grapple = $Grapple

var health = 100

var grounded : bool:
	get:
		ground_check = $GroundCheck
		return ground_check.has_overlapping_bodies() or ground_check.has_overlapping_areas()


@onready var handgun: PlayerGun = $handgun

## ====== Multiplayer START ======

var is_multiplayer: bool = false
var input_dir := Vector2.ZERO
var target_pos := Vector2.ZERO
var target_vel := Vector2.ZERO
var owner_id: int

## ======  Multiplayer END  ======

func _ready() -> void:
	
	## ====== Multiplayer START ======
	
	if multiplayer.has_multiplayer_peer():
		is_multiplayer = true
		owner_id = name.to_int()
		target_pos = global_position
		
		await get_tree().process_frame
		
		if has_node("MultiplayerSynchronizer"):
			$MultiplayerSynchronizer.set_multiplayer_authority(1)
			
		print("Initializing player ", name, " in Multiplayer...")
		print("   Player ", owner_id, 
		" | Local ID: ", multiplayer.get_unique_id(), 
		" | Authority: ", get_multiplayer_authority())
	else:
		$NamerTag.text = ""
		print("Initializing player in Singleplayer")
	
	## ======  Multiplayer END  ======
	
	ground_check.body_entered.connect(on_ground)
	ground_check.body_exited.connect(on_unground)
	ground_check.area_entered.connect(on_ground)
	ground_check.area_exited.connect(on_unground)
	
	if ship:
		on_ship_enter(ship)
	else:
		on_ship_exit()


func _physics_process(delta):
	
	# Authority lands on player on singleplayer mode
	if is_multiplayer_authority():
		apply_ground_body_transform()
		input_dir = input_dir.normalized().rotated(global_rotation)
		if seat:
			velocity = Vector2.ZERO # ship vel added later
			handgun.holster()
		elif grapple.wants_grapple():
			velocity = grapple.velocity(delta)
		elif grounded:
			# remove rotation?
			#rotate(Input.get_axis("rotate_left","rotate_right") * rotate_speed * delta)
			velocity = input_dir * walk_speed
		else:
			if Input.is_action_pressed("brake"):
				velocity -= velocity.normalized() * thrust_accel * delta
			else:
				velocity += input_dir * thrust_accel * delta
		move_and_slide()
		
		## ====== Multiplayer START ======

		for i in range(get_slide_collision_count()):
			var collision = get_slide_collision(i)
			var collider = collision.get_collider()
		
			if collider is RigidBody2D:
				var push_dir = -collision.get_normal()
				var impulse = push_dir * 200 * delta
				collider.apply_central_impulse(impulse)
		
		sync_state.rpc(global_position, velocity)
		
		## ======  Multiplayer END  ======
	
	else: 
		global_position = global_position.lerp(target_pos, 0.25)
		velocity = target_vel

## ====== Multiplayer START ======

func _process(delta: float) -> void:
	var is_local_player = multiplayer.get_unique_id() == owner_id
	
	if is_local_player:
		var dir = Input.get_vector("left", "right", "up", "down")
		
		if is_multiplayer_authority():
			input_dir = dir
		else:
			send_input.rpc_id(1, dir)

@rpc("any_peer", "call_remote", "reliable")
func send_input(dir: Vector2):
	var sender_id = multiplayer.get_remote_sender_id()
	if sender_id != owner_id:
		push_warning("Player %d tried to control player %d" % [sender_id, owner_id])
		return
		
	input_dir = dir
	
@rpc("authority", "call_remote", "unreliable")
func sync_state(pos: Vector2, vel: Vector2):
	if not is_multiplayer_authority():
		target_pos = pos
		target_vel = vel

## ======  Multiplayer END  ======

# currently interacts with the first overlapping interactable area, but this can be changed to nearest, last, all, ect.
func interact():
	var interactable = get_interactable()
	if interactable:
		interactable.interact(self)
		#print_debug("Player interacted with ", interactable)
			
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

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("player_shoot"):
		handgun.shoot_bullet()
	if event.is_action_pressed("holster_handgun"):
		if seat:
			return
		handgun.toggle_holster()
	if event.is_action_pressed("interact"):
		interact()
		return
	if seat and seat.room.has_method("handle_input"):
		seat.room.handle_input(event)
#region grounding
# called when ground check intersects with rb
func on_ground(_body : Node2D):
	if _body is RigidBody2D:
		ground_body = _body
		prev_ground_body_transform = ground_body.global_transform

func on_unground(_body : Node2D):
	if _body == ground_body:
		ground_body = null

# called when enter airlock
func on_ship_enter(new_ship : Ship):
	on_ground(new_ship)
	ship = new_ship
	print(name + " parent to ship")
	update_layers(true)

func on_ship_exit():
	# unground will be called when stops intersecting
	print(name + " parent to wordl")
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
		z_index = 4
	else:
		collision_layer = exterior_layer
		collision_mask = exterior_mask
		z_index = 12
#endregion

func take_damage(damage : int):
	health -= damage
	print("Damage Taken! Player now at %s health" % health)
