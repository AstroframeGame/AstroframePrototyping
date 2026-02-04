class_name Player
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
var ship : Ship:
	get:
		var gp = get_parent().get_parent()
		if gp is Ship:
			return gp
		return null

@onready var ground_check: Area2D = $GroundCheck
@onready var interact_check: Area2D = $InteractCheck
@onready var global_world : Node2D = $"../.."
@onready var grapple_visual: Line2D = $"Grapple"

var grapple_position : Vector2
var grappling : bool = false
@export var grapple_speed = 400

var grounded : bool:
	get:
		ground_check = $GroundCheck
		return ground_check.has_overlapping_bodies() or ground_check.has_overlapping_areas()

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
	var direction = Input.get_vector("left", "right", "up", "down")
	direction = direction.normalized().rotated(global_rotation)
	grapple()
	if seat:
		return
	rotate(Input.get_axis("rotate_left","rotate_right") * rotate_speed * delta)
	
	if grappling:
		velocity = (grapple_position - global_position).normalized() * grapple_speed
	elif grounded:
		velocity = direction * walk_speed
	else:
		if Input.is_action_pressed("brake"):
			velocity -= velocity.normalized() * thrust_accel * delta
		else:
			velocity += direction * thrust_accel * delta
		
	move_and_slide()

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
	#print(seat , seat and seat.room.has_method("handle_input"))
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

var ship_in : Ship:
	get :
		if get_parent().get_parent() is Ship:
			return get_parent().get_parent()
		return null
		
func on_ship_enter(ship : Ship):
	get_parent().call_deferred("reparent", ship, true)
	global_rotation = ship.global_rotation
	print("parent to ship")
	collision_layer = interior_layer
	collision_mask = interior_mask

func on_ship_exit():
	get_parent().call_deferred("reparent", global_world, true)
	print("parent to wordl")
	global_rotation = 0
	collision_layer = exterior_layer
	collision_mask = exterior_mask


func grapple():
	if grapple_position != null:
		var grapple_dist : float = (grapple_position - global_position).length()
		grappling = not seat and Input.is_action_pressed("grapple") and grapple_dist > 10
	
	if Input.is_action_just_pressed("grapple"):
		grapple_position = get_global_mouse_position()
	if not grappling:
		grapple_visual.visible = false
		return
	
	grapple_visual.visible = true
	grapple_visual.set_point_position(0, Vector2.ZERO)
	grapple_visual.set_point_position(1, to_local(grapple_position))
