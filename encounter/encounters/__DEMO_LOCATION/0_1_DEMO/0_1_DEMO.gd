extends Encounter

@export_file("*.tscn") var my_scene_path: String

@onready var faction_ship: Node = $ships/FACTION_PATROL
@onready var pirate_destroyer: Node = $ships/pirates/PIRATE_DESTROYER
@onready var to_kill: Array[Node] = [
	pirate_destroyer,
	$ships/pirates/PIRATE_FRIGATE,
	$ships/pirates/PIRATE_FRIGATE2,
	$ships/pirates/PIRATE_FRIGATE3
]

signal trigger_dialogue(npc: String, cat: String) 

var dead_pirates = 0

func _ready() -> void:	
	# scene info
	name = "0_1_DEMO"
	enc_base_dir = get_script().get_path().get_base_dir()
	objective = "Destroy pirate ships!"	# TBD: store and retrieve from encounter json dictionary
	encounter_scene = my_scene_path
	
	# win state setup
	for ship in to_kill:
		ship.connect( "ship_destroyed", win_check.bind() )	# when target destroyed, check for win
	
	# set npc metadata 
	faction_ship.name = "0_1_FACTION_PATROL"
	pirate_destroyer.name = "0_1_PIRATE_DESTROYER"
	
	# prep dialogue
	npcs_with_dialogue.push_back(faction_ship)
	npcs_with_dialogue.push_back(pirate_destroyer)
	
	# finish with parent setup
	super._ready()

func _process(delta: float) -> void:
	super._process(delta)
	
	# poll for dialogue
	# TODO: replace with signals?
	# is there a way to add an invisible field (radar, in range of ship sensors) around ships, 
	#	so when player enters it, a signal is emitted? 
	if faction_ship and player.global_position.distance_to(faction_ship.global_position) < 1000:
			trigger_dialogue.emit(faction_ship.name, "greeting")
	elif pirate_destroyer and player.global_position.distance_to(pirate_destroyer.global_position) < 1000:
			trigger_dialogue.emit(pirate_destroyer.name, "greeting")

func win_check() -> void:
	print("pirate ship died")
	dead_pirates += 1
	if dead_pirates >= to_kill.size():
		encounter_completed.emit(name)
