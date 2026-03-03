class_name DoorInteractable
extends Hex

'''
If the player interacts with this door, the room decides what happens.
'''


func can_interact() -> bool:
	return room is Room
	
func interact_hint() -> String:
	return "Exit Ship" if room.ship.my_character_inside() else "Enter Ship"

func interact(player : PlayerCharacter) -> void:
	if not can_interact():
		return
	if room.has_method("on_door_interact"):
		room.on_door_interact(player)
