extends Encounter

@onready var faction_ship: Node = $ships/FACTION_PATROL
@onready var pirate_destroyer: Node = $ships/pirates/PIRATE_DESTROYER
@onready var to_kill: Array[Node] = [
	pirate_destroyer,
	$ships/pirates/PIRATE_FRIGATE,
	$ships/pirates/PIRATE_FRIGATE2,
	$ships/pirates/PIRATE_FRIGATE3
]

signal trigger_dialogue(npc: String, cat: String) 

func _ready() -> void:	
	name = "0_1_DEMO"
	enc_base_dir = get_script().get_path().get_base_dir()
	init()
	objective = "Destroy pirate ships!"	# TBD: store and retrieve from encounter json dictionary
	
	win = func():
		if to_kill.size() > 0:
			to_kill.assign(to_kill.filter(func(t): return is_instance_valid(t)))
		return to_kill.size() == 0
	
	# set npc metadata 
	faction_ship.name = "0_1_FACTION_PATROL"
	pirate_destroyer.name = "0_1_PIRATE_DESTROYER"
	
	npcs.push_back(faction_ship)
	npcs.push_back(pirate_destroyer)
	
	preload_scene_dialogue()

func _process(delta: float) -> void:
	super._process(delta)
	
	if faction_ship and player.global_position.distance_to(faction_ship.global_position) < 1000:
			trigger_dialogue.emit(faction_ship.name, "greeting")
	elif pirate_destroyer and player.global_position.distance_to(pirate_destroyer.global_position) < 1000:
			trigger_dialogue.emit(pirate_destroyer.name, "greeting")
	pass
		
