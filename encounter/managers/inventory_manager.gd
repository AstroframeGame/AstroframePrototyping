extends Node

var scrap : int = 0
var rooms : Array[String] = [] # use the IDs that json would use

# this should be saved to a json called continue.json

# continue.json should have 
# - level existing data
# - seed and level generation data
# - playerstate (scrap, room_inventory)
# - current player ship

func _ready() -> void:
	pass # Replace with function body.

func save_game():
	pass

func load_game():
	pass
