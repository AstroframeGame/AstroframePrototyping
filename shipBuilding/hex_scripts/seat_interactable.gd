class_name SeatInteractable
extends Area2D

'''
If the player interacts with this seat, it will set the player's seat to its room.
Otherwise it will set the player's seat to null.
'''

@onready var room : Room = $"../.."

func interact_hint() -> String:
	return "[E] to Sit Down"

func interact(player : Player) -> void:
	if not room is Room:
		print_debug("Warning : tried to interact with a seat with no asociated room. Discarding input.")
		return
	if player.seat_room == room:
		player.seat_room = null
	else:
		player.seat_room = room
