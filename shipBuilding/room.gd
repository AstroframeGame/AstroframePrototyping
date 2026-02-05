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


## return index of augment in Augments Array
func augment_in_list(type:Variant)->int:
	for augment in augments:
		# needs better solution but how many times is someone
		# going to keep the base but repeatedly redo/undo
		# an augment ¯\_(ツ)_/¯
		if augment == null:
			continue
		if is_instance_of(augment, type):
			return augments.find(augment)
	return -1
	
func at_augment_limit(type:Variant, limit:int)->bool:
	var count = 0
	for augment in augments:
		if augment == null:
			continue
		if is_instance_of(augment, type):
			count += 1
	return count == limit

func pair_augments(augment_type:Variant)->void:
	ship.update_occupied_cells()
	for neighbor in ship.find_neighbors(self):
		if is_instance_of(neighbor, augment_type):
			if not neighbor.at_augment_limit(augment_type, 1): # temp
				neighbor.target_rooms.append(self)
				augments.append(neighbor)
