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

@onready var ground_check: Area2D = $GroundCheck

var grounded : bool:
	get:
		ground_check = $GroundCheck
		return ground_check.has_overlapping_bodies()

func _physics_process(_delta):
	var direction = Input.get_vector("left", "right", "up", "down")
	if grounded:
		velocity = direction * walk_speed
	else:
		if Input.is_action_pressed("brake"):
			velocity -= velocity.normalized() * thrust_accel * _delta
		else:
			velocity += direction * thrust_accel * _delta
		
	move_and_slide()
