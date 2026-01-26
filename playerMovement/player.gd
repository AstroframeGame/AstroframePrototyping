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

signal pass_unhandled_input(event : InputEvent)
var seat_room : Room = null

@onready var ground_check: Area2D = $GroundCheck
@onready var interact_check: Area2D = $InteractCheck

var grounded : bool:
	get:
		ground_check = $GroundCheck
		return ground_check.has_overlapping_bodies()

func _physics_process(_delta):
	if seat_room:
		return
	
	var direction = Input.get_vector("left", "right", "up", "down")
	if grounded:
		velocity = direction * walk_speed
	else:
		if Input.is_action_pressed("brake"):
			velocity -= velocity.normalized() * thrust_accel * _delta
		else:
			velocity += direction * thrust_accel * _delta
		
	move_and_slide()

# currently interacts with the first overlapping interactable area, but this can be changed to nearest, last, all, ect.
func interact():
	var interactable = get_interactable()
	if interactable:
		interactable.interact(self)
			
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
	if seat_room and seat_room.has_method("handle_input"):
		seat_room.handle_input(event)
