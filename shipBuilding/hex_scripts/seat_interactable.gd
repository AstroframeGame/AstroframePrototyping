class_name SeatInteractable
extends Hex

'''
If the player interacts with this seat, it will set the player's seat to its room.
Otherwise it will set the player's seat to null.
'''

var controlled_by : PlayerCharacter


func can_interact() -> bool:
	return room is Room and room.ship.my_character_inside()
func interact_hint() -> String:
	return "Sit Down"

func interact(player : PlayerCharacter) -> void:
	if not can_interact():
		return
	if player.seat == self:
		player.seat = null
		controlled_by = null
	else:
		player.seat = self
		controlled_by = player
		player.global_position = global_position
		#player.global_rotation = global_rotation # hack, may remove
