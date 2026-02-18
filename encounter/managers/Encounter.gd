class_name Encounter
extends Node

var enc_base_dir: String

var player: Node
var location: String
var settings: Dictionary
var dialogue: Dictionary
var npcs: Array
var gm : GameManager
var dialouge_runner : DialougeRunner
var objective: String
var win: Callable	# lambda defined in child encounter scripts

func _process(delta):
	# set player
	if not player:
		player = get_parent().multiplayer_manager.my_player
		player.global_position = $Ship.global_position
	
	# check win
	if win and win.call() == true:
		objective = "Success!"
		win = func(): pass	# overwrite to prevent further checking? # TODO: TEST THIS

func init():
	# set location
	location = enc_base_dir.split("/")[4]
	location = location.right(-2)
	
	# get settings from encounter dictionary
	settings = LevelStateManager.encounter_dictionary[location][name]

func preload_scene_dialogue():
	# get dialogue system
	gm = get_tree().root.get_node("Hub").get_node("GameManager")
	dialouge_runner = gm.dialogue_runner

	for npc in npcs:
		dialogue[npc.name] = LevelStateManager.load_dictionary("%s/dialogue/%s.json" % [enc_base_dir, npc.name])

func start_dialogue(npc: String, cat: String)->void:
	if dialogue[npc][cat].seen >= dialogue[npc][cat].limit:
		return
		
	var temp = "neutral" # TODO: in the future, this can be tuned by faction relatioship stats
	
	var random_pick = dialogue[npc][cat][temp].pick_random()
	var npc_dlg = parse_dialogue_to_array(dialogue[npc].name, random_pick)
	if npc_dlg:
		dialouge_runner.start(npc_dlg)
	dialogue[npc][cat].seen += 1

func parse_dialogue_to_array(npc: String, dlg: String):
	var split = dlg.split("\\ ")
	var result = []
	
	for d in split:
		result.push_back([npc, d])
	
	return result
