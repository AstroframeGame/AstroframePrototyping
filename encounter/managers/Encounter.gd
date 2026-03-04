class_name Encounter
extends Node

var enc_base_dir: String

var location: String			# location key
var settings: Dictionary		# encounter settings (prereqs, rewards, etc)
var reward_zone: Vector2		# where in the scene to put reward (using instead of player position)

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
var obj_panel: Label:
	set(value):
		obj_panel = value
		if obj_panel and objective != "":
			obj_panel.text = objective
			print("text set to: ", obj_panel.text)

var objective: String:
	set(value):
		objective = value
		if obj_panel:
			obj_panel.text = value
			print("text set to: ", obj_panel.text)

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
		#player.global_position = $Ship.global_position
		
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
		
	# dialogue at win
	dialogue["win"] = LevelStateManager.dialogue_dictionary[name]["YOU"]["win"]
	dialogue["lose"] = LevelStateManager.dialogue_dictionary[name]["YOU"]["lose"]

func start_dialogue(npc: String, cat: String)->void:
	if dialogue[npc][cat].has("seen"):
		return
	
	# TODO: in the future, tune this with faction relatioship stats
	var temp = "neutral" 
	
	var random_pick = dialogue[npc][cat][temp].pick_random()
	var npc_dlg = parse_dialogue_to_array(dialogue[npc].name, random_pick)
	if npc_dlg:
		dialouge_runner.start(npc_dlg)
	dialogue[npc][cat].seen = true

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
	
	# update LSM
	LevelStateManager.completed_encounters.push_front(enc_name)
	
	# grant rewards
	if rewards_granted: return
	for reward in prepacked_rewards:
		var r = reward.instantiate()
		gm.current_scene.call_deferred("add_child", r)
		r.set_deferred("global_position", reward_zone)
	
	# dialogue
	start_dialogue("win", "win")

func encounter_failed():
	start_dialogue("lose", "lose")
