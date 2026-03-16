class_name Encounter
extends Node

var player_ship: Node

var enc_base_dir: String
var location: String			# location key
var settings: Dictionary		# encounter settings (prereqs, rewards, etc)
var reward_zone: Vector2		# where in the scene to put reward (using instead of player position)
var won: bool

var queued_dialogue: Dictionary
signal trigger_dialogue(npc: String, cat: String) 
@warning_ignore("unused_signal")
signal got_objective() # used in demo scene

const GET_QUEUED_DIALOGUE = "$GET_QUEUED$"
const NULL_DIALOGUE = "$NULL$"

# reference to player (used for polling distance to npc ships, TEMP)
var player_spawn: Vector2:
	set(value):
		player_spawn = value
		if player and player_spawn:
			player.global_position = player_spawn

var player: Node:
	set(value):
		player = value
		if player and player_spawn:
			player.global_position = player_spawn

# objectives
var obj_number = -1
var obj_panel: Label:
	set(value):
		obj_panel = value
		if obj_panel and objective != "":
			obj_panel.text = objective

var objective: String:
	set(value):
		objective = value
		if obj_panel:
			obj_panel.text = value

var npcs_with_dialogue: Array	# defined in child, npcs with dialogue
var dialogue: Dictionary		# hold dictionary for quick lookup 

# globals
var gm : GameManager
var dialouge_runner : DialougeRunner

# completion
signal encounter_completed
var prepacked_rewards: Array
var rewards_granted: bool

func _ready():
	# set location
	location = enc_base_dir.split("/")[4]
	location = location.right(-2)
	
	# get settings from encounter dictionary
	settings = LevelStateManager.encounter_dictionary[location][name]
	
	# prepare dialogue
	preload_scene_dialogue()
	
	# setup signals
	encounter_completed.connect(_on_encounter_completed)
	
	# update LSM
	LevelStateManager.visited.push_front(location)
	
	# preload rewards
	preload_rewards()

func _process(_delta):
	# set player (used for polling distance to other entities in encounter)
	# may be best to replace with signals, see notes in 0_1_DEMO.gd
	if not player:
		player = get_parent().multiplayer_manager.my_player
		
	if not get_parent().multiplayer_manager.my_player_system:
		return
		
	if not obj_panel:
		obj_panel = get_parent().multiplayer_manager.my_player_system.find_child("PlayerUI").find_child("ScannerPanel").find_child("Content")
		var title = get_parent().multiplayer_manager.my_player_system.find_child("PlayerUI").find_child("ScannerPanel").find_child("Title")
		title.text = "Objectives"
		obj_panel.get_parent().scanner_active = false

func preload_scene_dialogue():
	# get dialogue system
	gm = get_tree().root.get_node("Hub").get_node("GameManager")
	dialouge_runner = gm.dialogue_runner

	for npc in npcs_with_dialogue:
		dialogue[npc.name] = LevelStateManager.dialogue_dictionary[name][npc.name]
		
	dialogue["YOU"] = LevelStateManager.dialogue_dictionary[name]["YOU"]

	# objective text
	dialogue["objective"] = LevelStateManager.dialogue_dictionary[name]["UI"]["UI_OBJECTIVE"]

func start_dialogue(npc: String, cat: String)->void:
	if not dialogue.has(npc): return
	if not dialogue[npc].has(cat): return
	if dialogue[npc][cat].has("seen"):
		# check against max if max exists
		if dialogue[npc][cat].has("max"):
			if typeof(dialogue[npc][cat].max) == TYPE_STRING:
				# handle infinity
				if dialogue[npc][cat].max == "INF":
					dialogue[npc][cat].max = INF
				# if it's an unrecognized string, default to 1
				# TODO: log a warning here
				else:
					dialogue[npc][cat].max = 1
			
			if dialogue[npc][cat].seen >= dialogue[npc][cat].max:
				return
			
			dialogue[npc][cat].seen += 1
		else:	# if max DNE, assume max is one
			return
	
	# TODO: in the future, tune this with faction relatioship stats
	var temp = "neutral" 
	
	var random_pick = dialogue[npc][cat][temp].pick_random()
	var npc_dlg = parse_dialogue_to_array(dialogue[npc].name, random_pick)
	if npc_dlg:
		dialouge_runner.start(npc_dlg)

	dialogue[npc][cat].seen = 1

func parse_dialogue_to_array(npc: String, dlg: String):
	var split = dlg.split("\\ ")
	var result = []
	
	for d in split:
		result.push_back([npc, d])
	
	return result

func preload_rewards():
	for reward in settings.rewards:
		prepacked_rewards.append(load(reward.path))

func _on_encounter_completed(enc_name: String):
	objective = "Complete!"
	won = true
	
	# update LSM
	LevelStateManager.completed_encounters.push_front(enc_name)
	
	# grant rewards
	if rewards_granted: return
	for reward in prepacked_rewards:
		var r = reward.instantiate()
		gm.current_scene.call_deferred("add_child", r)
		r.set_deferred("global_position", reward_zone)
	
	# dialogue
	start_dialogue("YOU", "win")

func set_ship_aggro(ship: Node, val: bool):
	trigger_dialogue.emit(ship.name, "aggro")
	ship.set_aggro.emit(val, player_ship)

func encounter_failed():
	start_dialogue("YOU", "lose")

func start_next_objective():
	obj_number += 1
	if(obj_number < dialogue["objective"]["neutral"].size()):
		objective = dialogue["objective"]["neutral"][obj_number]

func dialogue_setup(npc_ships: Array[Dictionary]):
	for npc in npc_ships:
		npcs_with_dialogue.push_back(npc.ship)
		
		# start dialogue queue for this ship
		if npc.init_dialogue != NULL_DIALOGUE:
			queued_dialogue[npc.ship.name] = npc.init_dialogue
		
		# connect signal to trigger dialogue
		var ap = npc.ship.get_any_auto_piloting();
		if ap:
			ap.detection_area.body_entered.connect(
				func(body): 
					if body and body is Ship and body.is_in_group("player_ship"):
						if is_instance_valid(npc.ship):
							trigger_dialogue.emit(npc.ship.name, GET_QUEUED_DIALOGUE)
			)

func _on_trigger_dialogue(npc: String, cat: String = GET_QUEUED_DIALOGUE) -> void:
	if cat == GET_QUEUED_DIALOGUE:		# default to queued dialog
		if not queued_dialogue.has(npc): return		# TODO: put a warning here
		cat = queued_dialogue[npc]

	start_dialogue(npc, cat)
