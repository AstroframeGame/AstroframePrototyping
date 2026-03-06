extends Encounter

@onready var player_ship: Node = $PlayerShip
@onready var research_ship: Node = $ships/RESEARCH_SATELLITE
@onready var faction_ship: Node = $ships/FACTION_PATROL
@onready var pirate_destroyer: Node = $ships/pirates/PIRATE_DESTROYER
@onready var to_kill: Array[Node] = [
	pirate_destroyer,
	$ships/pirates/PIRATE_FRIGATE,
	$ships/pirates/PIRATE_FRIGATE2,
	$ships/pirates/PIRATE_FRIGATE3,
]

var spoke_to_researchers = false
var queued_dialogue: Dictionary
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
		ship.connect( "ship_destroyed", _on_trigger_dialogue.bind("YOU", "PIRATE_KILLED") )
		ship.set_meta("type", "Pirate")
		ship.set_aggro.emit(true)	# pirate ships start aggro
	
	faction_ship.set_meta("type", "Faction")
	faction_ship.set_aggro.emit(false)	# faction ship starts friendly
	faction_ship.connect("on_hit", set_ship_aggro.bind(faction_ship, true)) # faction ship will aggro if you fire on them
	faction_ship.connect( "ship_destroyed", _on_trigger_dialogue.bind("YOU", "FACTION_KILLED") )
	
	player_ship.set_meta("type", "PlayerShip")
	player_ship.connect("ship_destroyed", encounter_failed)
	
	research_ship.connect("set_beacon", $markers/research_ship_marker2.set_beacon)
	research_ship.connect("on_hit", _on_trigger_dialogue.bind(research_ship.name, "aggro"))
	research_ship.connect( "ship_destroyed", _on_trigger_dialogue.bind("YOU", "RESEARCHERS_KILLED") )
	research_ship.set_beacon.emit(true)
	
	# set npc metadata 
	faction_ship.name = "0_1_FACTION_PATROL"
	pirate_destroyer.name = "0_1_PIRATE_DESTROYER"
	research_ship.name = "0_1_RESEARCHERS"
	
	# prep dialogue
	npcs_with_dialogue.push_back(faction_ship)
	npcs_with_dialogue.push_back(pirate_destroyer)
	npcs_with_dialogue.push_back(research_ship)
	
	queued_dialogue[faction_ship.name] = "greeting"
	queued_dialogue[pirate_destroyer.name] = "greeting"
	queued_dialogue[research_ship.name] = "greeting"
	
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
		if not faction_ship.get_auto_piloting():
			trigger_dialogue.emit(faction_ship.name, queued_dialogue[faction_ship.name])
	elif pirate_destroyer and player.global_position.distance_to(pirate_destroyer.global_position) < 1000:
		trigger_dialogue.emit(pirate_destroyer.name, queued_dialogue[pirate_destroyer.name])
	elif research_ship and player.global_position.distance_to(research_ship.global_position) < 1000:
		trigger_dialogue.emit(research_ship.name, queued_dialogue[research_ship.name])
		research_ship.set_beacon.emit(false)

func win_check() -> void:
	print("pirate ship died")
	dead_pirates += 1
	if dead_pirates >= to_kill.size():
		encounter_completed.emit(name)

func _on_trigger_dialogue(npc: String, cat: String) -> void:
	start_dialogue(npc, cat)
	if not won and not spoke_to_researchers and npc == research_ship.name:
		spoke_to_researchers = true
		dialouge_runner.on_dialogue_end.connect(start_next_objective, CONNECT_ONE_SHOT)

func set_ship_aggro(ship: Node, val: bool):
	trigger_dialogue.emit(ship.name, "aggro")
	ship.set_aggro.emit(val, player_ship)
	
func _on_encounter_completed(_name):
	super._on_encounter_completed(name)
	
	if is_instance_valid(faction_ship): queued_dialogue[faction_ship.name] = "win"
	if is_instance_valid(research_ship): queued_dialogue[research_ship.name] = "win"
