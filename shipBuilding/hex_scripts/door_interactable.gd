class_name DoorInteractable
extends Hex

'''
If the player interacts with this door, the room decides what happens.
'''

func interact_hint() -> String:
	return "[E] to Sit Down"

func interact(player : PlayerCharacter) -> void:
	if room is not Room:
		print_debug("Warning : tried to interact with a door with no asociated room. Discarding input.")
		return
	if room.has_method("on_door_interact"):
		room.on_door_interact(player)
