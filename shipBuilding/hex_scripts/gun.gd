class_name GunHex
extends Sprite2D

const PROJECTILE = preload("uid://devin6bdbcbay") # funny uid lol

@onready var room : Room = $".."
@onready var gunSprite : Sprite2D = $Sprite

func shoot():
	var proj : Projectile = PROJECTILE.instantiate()
	proj.add_collision_exception_with(get_node("../../")) # room.ship ?
	proj.global_position = global_position # should this be changed to barrel position?
	proj.rotation = gunSprite.global_rotation
	get_node("../../../Projectiles").add_child(proj) # should this be switched to a global group reference?
