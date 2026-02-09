extends Node

var player_data: Dictionary = {
	"inventory": {
		"scrap": 0, 	# currency + building material
		"modules": []	# schematics for building
	},
	"ship": null, 			# can we hold a reference to a ship object here?
	"current_location": [], # array for nesting (eg: Axuu space > black hole > space station)
	"quest_progress": {}	# better to store here or just look up in encounter dictionary?
}
