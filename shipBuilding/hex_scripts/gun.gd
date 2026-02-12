class_name GunHex
extends Sprite2D

const PROJECTILE = preload("uid://devin6bdbcbay") # funny uid lol

@onready var room : Room = $".."
@onready var gunSprite : Sprite2D = $Sprite
@onready var marker_2d: Marker2D = $Sprite/Marker2D
@onready var timer : Timer = $Timer
@export var cooldown : float = 0.5

func _ready():
	timer.wait_time = cooldown


var projectileSpeed = 200
func shoot(damage : int):
	if timer.time_left > 0:
		return
	timer.start()
	
	var proj : Projectile = PROJECTILE.instantiate()
	proj.initialize(gunSprite, room.ship.linear_velocity, projectileSpeed, Vector2.from_angle(gunSprite.global_rotation), marker_2d.global_position, damage)
	proj.add_collision_exception_with(room.ship)
	proj.owner_ship = room.ship
	
	var world = room.ship.get_parent()
	world.get_node("Projectiles").add_child(proj)
