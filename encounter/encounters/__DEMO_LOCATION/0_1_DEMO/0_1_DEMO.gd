extends Encounter

@onready var player_ship: Node = $PlayerShip
@onready var research_ship: Node = $ships/RESEARCH_SATELLITE
@onready var faction_ship: Node = $ships/FACTION_PATROL
@onready var pirate_destroyer: Node = $ships/pirates/PIRATE_DESTROYER
@onready var to_kill: Array[Node] = [
	pirate_destroyer,
	$ships/pirates/PIRATE_FRIGATE,
]

var spoke_to_researchers = false

signal trigger_dialogue(npc: String, cat: String) 
signal got_objective()

var dead_pirates = 0

func _ready() -> void:	
	# scene info
	name = "0_1_DEMO"
	enc_base_dir = get_script().get_path().get_base_dir()
	reward_zone = $RewardZone.global_position
	player_spawn = $PlayerSpawn.global_position
	
	# win state setup
	for ship in to_kill:
		ship.connect( "ship_destroyed", win_check.bind() )	# when target destroyed, check for win
		ship.set_meta("type", "Pirate")
	
	faction_ship.set_meta("type", "Faction")
	player_ship.set_meta("type", "PlayerShip")
	player_ship.connect("ship_destroyed", encounter_failed)
	
	# set npc metadata 
	faction_ship.name = "0_1_FACTION_PATROL"
	pirate_destroyer.name = "0_1_PIRATE_DESTROYER"
	research_ship.name = "0_1_RESEARCHERS"
	
	# prep dialogue
	npcs_with_dialogue.push_back(faction_ship)
	npcs_with_dialogue.push_back(pirate_destroyer)
	npcs_with_dialogue.push_back(research_ship)
	
	research_ship.connect("set_beacon", $markers/research_ship_marker2.set_beacon)
	research_ship.set_beacon.emit(true)
	
	got_objective.connect(start_next_objective)
	trigger_dialogue.connect(_on_trigger_dialogue)
	
	# finish with parent setup
	super._ready()
	start_next_objective()

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
	elif research_ship and player.global_position.distance_to(research_ship.global_position) < 1000:
		trigger_dialogue.emit(research_ship.name, "greeting")
		research_ship.set_beacon.emit(false)

func win_check() -> void:
	print("pirate ship died")
	dead_pirates += 1
	if dead_pirates >= to_kill.size():
		encounter_completed.emit(name)

func _on_trigger_dialogue(npc: String, cat: String) -> void:
	start_dialogue(npc, cat)
	if not spoke_to_researchers and npc == research_ship.name:
		spoke_to_researchers = true
		dialouge_runner.dialogue_completed.connect(start_next_objective, CONNECT_ONE_SHOT)
