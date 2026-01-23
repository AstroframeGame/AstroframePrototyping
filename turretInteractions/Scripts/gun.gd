extends Sprite2D

const PROJECTILE = preload("uid://devin6bdbcbay")

@onready var parentRoom : Room = get_parent()
@onready var gunSprite : Sprite2D = $Sprite

func shoot():
	var proj : Projectile = PROJECTILE.instantiate()
	proj.add_collision_exception_with(get_node("../../"))
	proj.global_position = global_position
	proj.rotation = gunSprite.global_rotation
	get_node("../../../Projectiles").add_child(proj)
