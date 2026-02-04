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

var _seat : SeatInteractable = null
var seat : SeatInteractable :
	get:
		return _seat
	set(value):
		_seat = value

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
		return ground_check.has_overlapping_bodies()
		
var health = 100

func _ready() -> void:
	ground_check.body_entered.connect(on_ground)
	ground_check.body_exited.connect(on_unground)

func _physics_process(_delta):
	var direction = Input.get_vector("left", "right", "up", "down")
	direction = direction.normalized()
	grapple()
	if seat:
		return
	
	if grappling:
		velocity = (grapple_position - global_position).normalized() * grapple_speed
	elif grounded:
		velocity = direction * walk_speed
	else:
		if Input.is_action_pressed("brake"):
			velocity -= velocity.normalized() * thrust_accel * _delta
		else:
			velocity += direction * thrust_accel * _delta
		
	move_and_slide()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("player_shoot"):
		get_node("handgun").shootBullet()
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
func on_ship_exit():
	get_parent().call_deferred("reparent", global_world, true)
	print("parent to wordl")
	global_rotation = 0


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

func takeDamage(damage : int):
	health -= damage
	print("Damage Taken! Player now at %s health" % health)
