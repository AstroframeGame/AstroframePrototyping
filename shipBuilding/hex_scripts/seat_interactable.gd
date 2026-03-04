class_name SeatInteractable
extends Hex

'''
If the player interacts with this seat, it will set the player's seat to its room.
Otherwise it will set the player's seat to null.
'''

var controlled_by : PlayerCharacter


func can_interact() -> bool:
	if room is Room:
		if room.ship != null:
			if room.ship.my_character_inside():
				return true
	return false
func interact_hint() -> String:
	return "Sit Down"

func interact(player : PlayerCharacter) -> void:
	if not room is Room:
		print_debug("Warning : tried to interact with a seat with no asociated room. Discarding input.")
		return
	if not room.ship.my_character_inside() and player.ship != room.ship:
	if not can_interact():
		return
	if player.seat == self:
		player.seat = null
		controlled_by = null
		if room.has_method("player_getup_interact"):
			room.player_getup_interact()
	else:
		player.seat = self
		controlled_by = player
		player.global_position = global_position
		#player.global_rotation = global_rotation # hack, may remove
		if room.has_method("player_sit_interact"):
			room.player_sit_interact(player)
