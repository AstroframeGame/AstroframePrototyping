extends Sprite2D

const PROJECTILE = preload("uid://devin6bdbcbay")

@onready var parentRoom : Room = get_parent()

func shoot():
	var proj : Projectile = PROJECTILE.instantiate()
	proj.add_collision_exception_with(get_node("../../"))
	proj.global_position = global_position
	proj.rotation = get_node("../../").rotation - 1.5
	get_node("../../../Projectiles").add_child(proj)
	print("shooted") 
	# why tf not instantiating
