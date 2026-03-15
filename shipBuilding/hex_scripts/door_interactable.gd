class_name DoorInteractable
extends Hex

'''
If the player interacts with this door, the room decides what happens.
'''


func can_interact() -> bool:
	return room is Room and room.ship and room.ship.get_players_pushing().is_empty()
	
func interact_hint() -> String:
	var inside = false
	if room != null and room.ship != null and room.ship.my_character_inside():
		inside = true
	return "Exit Ship" if inside else "Enter Ship"

func interact(player : PlayerCharacter) -> void:
	if room is not Room:
		print_debug("Warning : tried to interact with a door with no asociated room. Discarding input.")
	if not can_interact():
		return
	if room.has_method("on_door_interact"):
		room.on_door_interact(player)
