class_name GunHex
extends Sprite2D

const PROJECTILE = preload("uid://devin6bdbcbay") # funny uid lol

@onready var room : Room = $".."
@onready var gunSprite : Sprite2D = $Sprite
var damage = 20
var projectileSpeed = 200
func shoot():
	var proj : Projectile = PROJECTILE.instantiate()
	proj.initialize(gunSprite, room.ship.linear_velocity, projectileSpeed, Vector2.from_angle(gunSprite.global_rotation), damage)
	proj.add_collision_exception_with(room.ship)
	
	var world = room.ship.get_parent()
	world.get_node("Projectiles").add_child(proj)
