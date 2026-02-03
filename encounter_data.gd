# encounter_data.gd
# global autoload for encounter data
extends Node

var ship_types = {
	"FACTION": 1,
	"CIVILIAN": 2,
	"SCIENCE": 3,
	"CRIMINAL": 4
}

var locations = {
	"ASTRO_OBJ": 1,
	"STRUCTURE": 2,
	"SPACE_STATION": 3,
	"MILITARY_BASE": 4,
	"BATTLEFIELD": 5,
	"VOID": 6
}

var encounters = {
	# ASTRO_OBJ
	11: "faction ship on patrol",
	12: "neutral travel",
	13: "research",
	14: "pirate in hiding",
	# STRUCTURE
	21: "refuelling",
	22: "refuelling",
	23: "refeulling",
	24: "refeulling",
	# SPACE_STATION
	31: "faction scanning station",
	32: "space hotel arrival",
	33: "research center",
	34: "station under siege",
	# MILITARY_BASE
	41: "performing drills",
	42: "civilian placed under arrest",
	43: "state-sponsored research",
	44: "ship heist",
	# BATTLEFIELD
	51: "battle",
	52: "distress",
	53: "distress",
	54: "opportunistic theft",
	# VOID
	61: "patrol",
	62: "distress",
	63: "research",
	64: "hiding"
}

func get_event_id(location_type: String, ship_type: String) -> int:
	var location_val = locations.get(location_type, 0)
	var ship_val = ship_types.get(ship_type, 0)
	return location_val * 10 + ship_val

func get_encounter_description(location_type: String, ship_type: String) -> String:
	var event_id = get_event_id(location_type, ship_type)
	return encounters.get(event_id, "DEFAULT")
