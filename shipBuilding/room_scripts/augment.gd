class_name Augment
extends Room

# define an instance of the room type that the augment should target
@export var target_rooms : Array[Room]
@export var target_room : Room

# func to fill out target_rooms
func find_target_rooms(augment_type: Variant, target_type: Variant):
	for neighbor in ship.find_neighbors(self):
		if target_rooms.size() == 0 and is_instance_of(neighbor, target_type):
			# check that target.augments isnt at the limit for this particular augmentt
			if neighbor.augment_in_list(augment_type) > -1:
				continue
			target_rooms.append(neighbor)
			neighbor.augments.append(self)
