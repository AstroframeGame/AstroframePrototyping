# https://github.com/SentientDragon5/Trail2D-addon/edit/master/addons/trail_2d/trail_2d.gd
# 11/4/25 fixed global -> local space conversion
class_name Trail2D
extends Line2D

@export_category('Trail')
@export var length : float = 10

@onready var parent : Node2D = get_parent()
var offset : Vector2 = Vector2.ZERO

func _ready() -> void:
	offset = position
	#points = []
	#top_level = true

func _physics_process(_delta: float) -> void:
	pass
	#global_position = Vector2.ZERO

	#var point : Vector2 = parent.to_global(offset)
	
	#add_point(to_local(point), 0)
	
	#if get_point_count() > length:
		#remove_point(get_point_count() - 1)
