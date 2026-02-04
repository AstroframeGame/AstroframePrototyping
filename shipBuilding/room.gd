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
#export for debugging
@export var augments : Array[Augment]


func augment_in_list(_type:Variant)->int:
	for augment in augments:
		# needs better solution but how many times is someone
		# going to keep the base but repeatedly redo/undo
		# an augment ¯\_(ツ)_/¯
		if augment == null:
			continue
		if is_instance_of(augment, _type):
			return augments.find(augment)
	return -1
	
