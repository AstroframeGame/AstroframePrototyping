class_name SeatInteractable
extends Hex

'''
If the player interacts with this seat, it will set the player's seat to its room.
Otherwise it will set the player's seat to null.
'''

var controlled_by : PlayerCharacter

func interact_hint() -> String:
	return "[E] to Sit Down"

func interact(player : PlayerCharacter) -> void:
	if not room is Room:
		print_debug("Warning : tried to interact with a seat with no asociated room. Discarding input.")
		return
	if not room.ship.my_character_inside():
		return
	if player.seat == self:
		player.seat = null
		controlled_by = null
	else:
		print("Player Sat")
		player.seat = self
		controlled_by = player
		player.global_position = global_position
		#player.global_rotation = global_rotation # hack, may remove
		if room.has_method("player_sit_interact"):
			room.player_sit_interact(player)
