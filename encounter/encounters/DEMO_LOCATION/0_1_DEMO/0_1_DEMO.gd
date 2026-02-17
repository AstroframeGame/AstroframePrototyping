extends Encounter

@onready var faction_ship: Node = $ships/FACTION_PATROL
@onready var pirate_destroyer: Node = $ships/pirates/PIRATE_DESTROYER

signal trigger_dialogue(npc: String, cat: String) 

func _ready() -> void:	
	name = "0_1_DEMO"
	enc_base_dir = get_script().get_path().get_base_dir()
	location = enc_base_dir.split("/")[4]
	settings = LevelStateManager.encounter_dictionary[location][name]
	
	# set npc metadata 
	faction_ship.name = "0_1_FACTION_PATROL"
	pirate_destroyer.name = "0_1_PIRATE_DESTROYER"
	
	npcs.push_back(faction_ship)
	npcs.push_back(pirate_destroyer)
	
	preload_scene_dialogue()

func _process(delta: float) -> void:
	if not player:
		player = get_parent().multiplayer_manager.my_player
	
	if player.global_position.distance_to(faction_ship.global_position) < 1000:
			trigger_dialogue.emit(faction_ship.name, "greeting")
	elif player.global_position.distance_to(pirate_destroyer.global_position) < 1000:
			trigger_dialogue.emit(pirate_destroyer.name, "greeting")
	pass
	
