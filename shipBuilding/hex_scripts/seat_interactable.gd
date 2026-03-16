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
			return true
	return false
func interact_hint() -> String:
	if controlled_by:
		return "Stand Up"
	return "Sit Down"

func interact(player : PlayerCharacter) -> void:
	if is_multiplayer_authority():
		if not room is Room:
			print_debug("Warning : tried to interact with a seat with no asociated room. Discarding input.")
			return
		if not room.ship.my_character_inside() and player.ship != room.ship:
			return

		sync_interact.rpc(player.get_path())

@rpc("any_peer", "call_local", "reliable")
func sync_interact(player_path: NodePath):
	var player = get_node_or_null(player_path)
	if not player:
		push_warning("[seat.gd/sync_interact()]: Authority sent unrecognizable path")
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
		if room.has_method("player_sit_interact"):
			room.player_sit_interact(player)
		
