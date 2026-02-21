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
@onready var multiplayer_manager : MultiplayerManager = $".."

@onready var grapple: Grapple = $Grapple

var health = 100

var grounded : bool:
	get:
		ground_check = $GroundCheck
		return ground_check.has_overlapping_bodies() or ground_check.has_overlapping_areas()


@onready var handgun: PlayerGun = $handgun

func _ready() -> void:
	ground_check.body_entered.connect(on_ground)
	ground_check.body_exited.connect(on_unground)
	ground_check.area_entered.connect(on_ground)
	ground_check.area_exited.connect(on_unground)
	
	
	if ship:
		on_ship_enter(ship)
	else:
		on_ship_exit()


func _physics_process(delta):
	apply_ground_body_transform()
	
	var direction = Input.get_vector("left", "right", "up", "down")
	direction = direction.normalized().rotated(global_rotation)
	pushing = ground_body != null and ground_body is Ship and ship == null and Input.is_action_pressed("ship_push")
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
		var goal_vel = Vector2.ZERO
		if Input.is_action_pressed("brake"):
			velocity = velocity.move_toward(Vector2.ZERO, thrust_accel * delta)
		else:
			goal_vel = velocity + direction * thrust_move
			velocity = velocity.move_toward(goal_vel, thrust_accel * delta)
	
	move_and_slide()

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

# called when enter airlock
func on_ship_enter(new_ship : Ship):
	on_ground(new_ship)
	ship = new_ship
	#print(name + " parent to ship")
	update_layers(true)

func on_ship_exit():
	# unground will be called when stops intersecting
	#print(name + " parent to wordl")
	update_layers(false)
	ship = null

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
	
