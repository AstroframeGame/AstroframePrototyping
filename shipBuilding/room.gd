class_name Room
extends Node2D

var ship : Ship:
	get:
		return get_parent() as Ship

var rot_index : int:
	get:
		return int(round(rotation / (PI / 3.0)))
var grid_pos : Vector2i:
	get:
		return ship.world_to_grid(global_position)

# not sure how durability is going to work, but probably once a room takes enough damage, it becomes
# inoperable or breaks
@export var durability = 40


func _ready() -> void:
	print(ship.find_neightbors(self))
