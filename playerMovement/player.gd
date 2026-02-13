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

var ship : Ship
# for fake parenting
var prev_ship_transform : Transform2D

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

func calc_ship_velocity(delta : float) -> Vector2:
	var ship_velocity = Vector2.ZERO
	if is_instance_valid(ship):
		var ship_diff = ship.global_transform.origin - prev_ship_transform.origin
		var ship_rot_diff = ship.global_rotation - prev_ship_transform.get_rotation()
		if prev_ship_transform != Transform2D():
			var linear_vel = ship_diff / delta
			var radius_vec = global_position - ship.global_position
			var angular_vel = ship_rot_diff / delta
			var tangential_vel = Vector2(-radius_vec.y, radius_vec.x) * angular_vel
			
			ship_velocity = linear_vel + tangential_vel
			rotate(ship_rot_diff)
			print("rot by ", ship_rot_diff)
		prev_ship_transform = ship.global_transform
	return ship_velocity

func _physics_process(delta):
	var ship_velocity = calc_ship_velocity(delta)
	
	var direction = Input.get_vector("left", "right", "up", "down")
	direction = direction.normalized().rotated(global_rotation)
	if seat:
		velocity = Vector2.ZERO # ship vel added later
		handgun.holster()
	elif grapple.wants_grapple():
		velocity = grapple.velocity(delta)
	elif grounded:
		# remove rotation?
		#rotate(Input.get_axis("rotate_left","rotate_right") * rotate_speed * delta)
		velocity = direction * walk_speed
	else:
		if Input.is_action_pressed("brake"):
			velocity -= velocity.normalized() * thrust_accel * delta
		else:
			velocity += direction * thrust_accel * delta
	
	velocity += ship_velocity	
	move_and_slide()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("player_shoot"):
		handgun.shoot_bullet()
	if event.is_action_pressed("holster_handgun"):
		if seat:
			return
		if handgun.get_holster():
			handgun.unholster()
			return
		handgun.holster()
# currently interacts with the first overlapping interactable area, but this can be changed to nearest, last, all, ect.
func interact():
	var interactable = get_interactable()
	if interactable:
		interactable.interact(self)
		print_debug("Player interacted with ", interactable)
			
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
	if event.is_action_pressed("interact"):
		interact()
		return
	if seat and seat.room.has_method("handle_input"):
		seat.room.handle_input(event)

func on_ground(_body : Node2D):
	#print(body)
	pass
	#if body is Ship:
		#on_ship_enter(body)
func on_unground(_body : Node2D):
	#print("exot", body)
	pass
	#if body is Ship:
		#on_ship_exit(body)
		#pass

func on_ship_enter(new_ship : Ship):
	ship = new_ship
	prev_ship_transform = ship.global_transform
	print("parent to ship")
	collision_layer = interior_layer
	collision_mask = interior_mask

func on_ship_exit():
	ship = null
	prev_ship_transform = Transform2D()
	print("parent to wordl")
	collision_layer = exterior_layer
	collision_mask = exterior_mask

func takeDamage(damage : int):
	health -= damage
	print("Damage Taken! Player now at %s health" % health)
