class_name GunHex
extends Sprite2D

const PROJECTILE = preload("uid://devin6bdbcbay") # funny uid lol

@onready var room : Room = $".."
@onready var gunSprite : Sprite2D = $Sprite
@onready var timer : Timer = $Timer
@export var cooldown : float = 0.5

func _ready():
	timer.wait_time = cooldown

func shoot():
	if timer.time_left > 0:
		return
	timer.start()
	
	var proj : Projectile = PROJECTILE.instantiate()
	proj.initialize(gunSprite, room.ship.linear_velocity, Vector2.from_angle(gunSprite.global_rotation))
	proj.add_collision_exception_with(room.ship)
	
	var world = room.ship.get_parent()
	world.get_node("Projectiles").add_child(proj)
