class_name GunHex
extends Sprite2D

const PROJECTILE = preload("uid://devin6bdbcbay") # funny uid lol

@onready var room : Room = $".."
@onready var gunSprite : Sprite2D = $Sprite

func shoot():
	var proj : Projectile = PROJECTILE.instantiate()
	proj.initialize(gunSprite, room.ship.linear_velocity)
	proj.add_collision_exception_with(room.ship)
	# also ignore any players or things inisde ship?
	#proj.global_position = global_position # should this be changed to barrel position?
	#proj.rotation = gunSprite.global_rotation # moved to initialize
	var world = room.ship.get_parent()
	world.get_node("Projectiles").add_child(proj) # not most elegent way
