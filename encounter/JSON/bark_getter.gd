extends Node

# Split barks into an array that can be loaded in dialogue system

# named entities
var named_entities = [
  "A_1_PIRATE_DESTROYER",
  "A_1_PIRATE_FRIGATE",
  "A_1_FACTION_PATROL"
]

var bark_dictionary = get_bark_dictionary()

# load data from encounter lookup json
# https://forum.godotengine.org/t/how-do-i-read-json-files/38063
func get_bark_dictionary():
	var res = {}
	for npc in named_entities:
		var json = JSON.new()
		var path = "res://encounter/JSON/barks/%s.json" % npc
		var file = FileAccess.open(path, FileAccess.READ)
		
		if !file:
			continue
		
		var json_text = file.get_as_text()
		file.close()
		
		var error = json.parse(json_text)
		if error == OK:
			res[npc] = json.data
		else:
			print("JSON Parse Error: ", json.get_error_message(), " in ", json_text)
	return res
	
func retrieve(npc: String, cat: String):
	if bark_dictionary.has(npc) and bark_dictionary[npc][cat]:
		var temperature = "neutral" # TODO: use npc state to pick temperature
		var npc_name = bark_dictionary[npc].name
		
		var bark_arr = bark_dictionary[npc][cat]
		if bark_arr.limit > -1 and (bark_arr.seen < bark_arr.limit):
			bark_arr.seen += 1
			var bark = bark_arr[temperature].pick_random()
			return parse_bark_to_array(npc_name, bark)
		else:
			return null
	else:
		return [
			[ "ERROR", "Bark not found: NPC[%s], CATEGORY[%s]" % [npc, cat] ]
		]

func parse_bark_to_array(npc_name: String, bark: String):
	var split = bark.split("\\ ")
	var result = []
	
	for b in split:
		result.push_back([npc_name, b])
	
	return result
