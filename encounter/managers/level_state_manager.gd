# encounter_data.gd
# global autoload for encounter data
extends Node

var dictionary = get_encounter_dictionary()

# can grab these arrays from Scripted Encounters > JSON Exports
# https://docs.google.com/spreadsheets/d/1s3iz44CgmWNPqo6dqfTeVFWs66qc85rx3uyXpwCjm_w/edit?gid=1533284224#gid=1533284224
var keys = [
  "A_3_RESCUE",
  "A_1_PIRATES",
  "A_2_ENEMY",
  "B_3_RESCUE",
  "D_3_RESCUE",
  "C_3_RESCUE",
  "0_INTRO",
  "1_SENSOR",
  "A_0_SOS",
  "B_0_SOS",
  "C_0_SOS",
  "D_0_SOS",
  "B_1_",
  "B_2_",
  "C_1_",
  "C_2_",
  "D_1_",
  "D_2_"
]
var items = [
  "#OLD_MAP",
  "MID_RANGE_SENSOR",
  "#WARP_DRIVE",
  "SKILL_POINT",
  "RUSTY_GRAPPLING_HOOK",
  "PIRATE_FAVOR"
]

@export_file("*.tscn") var encounter_paths: Array[String]

func _ready():
	
	
# load data from encounter lookup json
# https://forum.godotengine.org/t/how-do-i-read-json-files/38063
func get_encounter_dictionary():
	var json = JSON.new()
	var file = FileAccess.open("res://encounter/JSON/encounter_dictionary.json", FileAccess.READ)
	var json_text = file.get_as_text()
	file.close()
	
	var error = json.parse(json_text)
	if error == OK:
		return json.data
	else:
		print("JSON Prase Error: ", json.get_error_message(), " in ", json_text)
