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
var pushing :bool #set in physics process
var push_dir
var push_brake
var input_enabled

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

var ship: Ship


@onready var ground_check: Area2D = $GroundCheck
@onready var interact_check: Area2D = $InteractCheck
@onready var multiplayer_manager : MultiplayerManager = $"../.."

@onready var grapple: Grapple = $Grapple

var health = 100
var is_dead : bool = false

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

var pushed: bool = false
var input_dir := Vector2.ZERO
var mouse_pos := Vector2.ZERO
var ship_pushed: bool = false
var is_shooting: bool = false
var is_holstering: bool = false
var was_holstering: bool = false
var is_interacting: bool = false
var was_interacting: bool = false
var screen_mouse_pos := Vector2.ZERO
var event_in_room: StringName
var username: String
## ======  Multiplayer END  ======
#endregion

#region ReadyFunction
func _ready() -> void:
	ground_check.body_entered.connect(on_ground)
	ground_check.body_exited.connect(on_unground)
	ground_check.area_entered.connect(on_ground)
	ground_check.area_exited.connect(on_unground)
	
	## ====== Multiplayer START ======
	
	is_multiplayer = multiplayer_manager.is_multiplayer
	input_enabled = true
	target_pos = global_position
	
	await get_tree().process_frame

	if has_node("MultiplayerSynchronizer"):
		$MultiplayerSynchronizer.set_multiplayer_authority(1)

	if has_node("Grapple"):
		$Grapple.set_multiplayer_authority(1)
	
	if is_multiplayer:
		owner_id = name.to_int()

		print("Initializing player ", name, " in Multiplayer...")
		print("   Player ", owner_id, 
		" | Local ID: ", multiplayer.get_unique_id(), 
		" | Authority: ", get_multiplayer_authority())
	else:
		owner_id = 1
		is_local_player = false
		
		$NamerTag.text = ""
		print("Initializing player in Singleplayer")

	## ======  Multiplayer END  ======
	
	if ship:
		on_ship_enter(ship)
	else:
		on_ship_exit()
#endregion

func _physics_process(delta):
	apply_ground_body_transform()
	
	var gm : GameManager = get_tree().root.get_node("Hub").get_node("GameManager")
	var menu_manager = gm.menus
	input_enabled = menu_manager and not (menu_manager.is_open("Paused") or menu_manager.is_open("Settings"))
		
	if not input_enabled:
		return
	
	var direction = Input.get_vector("left", "right", "up", "down")
	direction = direction.normalized().rotated(global_rotation)
	if Input.is_action_just_pressed("ship_push"):
		if pushing:
			pushing = false
		else:
			pushing = ground_body != null and ground_body is Ship and ship == null
	push_dir = direction
	push_brake = Input.is_action_pressed("brake")
	#print(ground_body != null , ground_body is Ship , ship == null , Input.is_action_pressed("ship_push"))
	
	if seat or pushing:
		velocity = Vector2.ZERO # ship vel added later
		handgun.holster()
	elif grapple.wants_grapple():
		velocity = grapple.velocity(delta)
	elif grounded:
		# remove rotation?
		#rotate(Input.get_axis("rotate_left","rotate_right") * rotate_speed * delta)
		velocity = direction * walk_speed
	else:
		ground_body = null
		var goal_vel = Vector2.ZERO
		if Input.is_action_pressed("brake"):
			velocity = velocity.move_toward(Vector2.ZERO, thrust_accel * delta)
		else:
			goal_vel = velocity + direction * thrust_move
			velocity = velocity.move_toward(goal_vel, thrust_accel * delta)
	
	move_and_slide()

# currently interacts with the first overlapping interactable area, but this can be changed to nearest, last, all, ect.
func interact():
	print("\n=== REACHED INTERACT() ===\n")
	if not input_enabled:
		return
	var interactable = get_interactable()
	print("   Interactable: ", interactable)
	if interactable:
		interactable.interact(self)
		print_debug("[", multiplayer.get_unique_id(), "]: ", name, " interacted with ", interactable)
			
func get_interactable() -> Node2D:
	for area in interact_check.get_overlapping_areas():
		if area.has_method("can_interact"):
			if not area.can_interact():
				continue
		if area.has_method("interact"):
			return area
	return null

func get_interactable_hint() -> String:
	var interactable = get_interactable()
	if interactable:
		if interactable.has_method("interact_hint"):
			return interactable.interact_hint()
		return "interact with " + interactable.name
	return ""
#endregion

#region UnhandledInputs
var shooting = false

func _unhandled_input(event: InputEvent) -> void:
	if is_local_player:
		var interacting = false
		var room_input = ""
		var holstered = false
		
		if event.is_action_pressed("player_shoot"):
			shooting = true
		if event.is_action_released("player_shoot"):
			shooting = false
		
		if event.is_action_pressed("holster_handgun"):
			if seat:
				return
			holstered = true
	
		if event.is_action_pressed("interact"):
			interacting = true
			print("Pushed interact")
			
		if seat and seat.room.has_method("handle_input"):
			for a in InputMap.get_actions():
				if event.is_action(a):
					room_input = a
					break
			
		if is_multiplayer_authority():
			is_shooting    = shooting
			is_holstering  = holstered
			event_in_room  = room_input
			is_interacting = interacting
		else:
			send_unhandled_inputs.rpc_id(1, shooting, holstered, interacting, room_input)
	
@rpc("any_peer", "call_remote", "reliable")
func send_unhandled_inputs(shoot: bool, holstered: bool, interacting: bool, room_input: StringName):
	var sender_id = multiplayer.get_remote_sender_id()
	if sender_id != owner_id:
		push_warning("Player %d tried to control player %d" % [sender_id, owner_id])
		return
	
	is_shooting    = shoot
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
	var prev_ship = get_tree().get_first_node_in_group("player_ship")
	if prev_ship:
		print("Previous ship exists, removing from group")
		prev_ship.remove_from_group("player_ship")
	ship = new_ship
	if self not in new_ship.players:
		print("   Appended self into ship.players")
		new_ship.players.append(self)
	else:
		push_warning("[Player.gd]: {Warning}, player requested to enter ship when in ship")
	rotation = ship.rotation
	#print(name + " parent to ship")
	ship.add_to_group("player_ship")
	# always do this
	update_layers(true)
	on_ground(ship)
	# if ship is also pirate ship warn nearby pirates
	var pirate_pilot = ship.get_auto_piloting()
	if ship.is_in_group("pirate_ship") and pirate_pilot != null:
		for body in pirate_pilot.detection_area.get_overlapping_bodies():
			if body.is_in_group("pirate_ship") and body != ship:
				body.get_auto_piloting().target_candidate = ship
				body.get_auto_piloting().on_player_ship_detected()
				print("warned " + str(body))
	update_layers(true)

func on_ship_exit():
	# unground will be called when stops intersecting
	#print(name + " parent to wordl")
	if ship and self in ship.players:
		ship.players.remove_at(ship.players.find(self))
	ship = null
	rotation = 0
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


func take_damage(damage : int, _vfx_pos:Vector2):
	if health > 0 and health - damage > 0:
		health -= damage
		return
	else:
		input_enabled = false
		var gm : GameManager = get_tree().root.get_node("Hub").get_node("GameManager")
		
		gm.dialogue_runner.start([["You", "*ack"], ["You","*bleh"]])
		await gm.dialogue_runner.on_dialogue_end
		gm.quit_to_list()
		gm.menus.open_menu("GameOver")

func seppuku():
	take_damage(999, global_position)
