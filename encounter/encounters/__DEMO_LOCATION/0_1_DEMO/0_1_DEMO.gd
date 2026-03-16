extends Encounter

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
var dead_pirates = 0

func _ready() -> void:	
	LevelStateManager.current_encounter = self
	player_ship = $PlayerShip
	
	# scene info
	name = "0_1_DEMO"
	enc_base_dir = get_script().get_path().get_base_dir()
	reward_zone = $RewardZone.global_position
	player_spawn = $PlayerSpawn.global_position
	
	got_objective.connect(start_next_objective)
	trigger_dialogue.connect(_on_trigger_dialogue)
	
	player_ship.set_meta("type", "PlayerShip")
	player_ship.connect("ship_destroyed", encounter_failed)

	#region NPC SETUP 
	# pirate ships setup
	pirate_destroyer.name = "0_1_PIRATE_DESTROYER"
	for ship in to_kill:
		ship.connect( "ship_destroyed", win_check.bind() )	# when target destroyed, check for win
		ship.connect( "ship_destroyed", _on_trigger_dialogue.bind("YOU", "PIRATE_KILLED") )
		ship.set_meta("type", "Pirate")
		ship.set_aggro.emit(true)	# pirate ships start aggro
	
	# faction ship setup
	faction_ship.name = "0_1_FACTION_PATROL"
	faction_ship.set_meta("type", "Faction")
	faction_ship.set_aggro.emit(false)	# faction ship starts friendly
	faction_ship.connect("on_hit", set_ship_aggro.bind(faction_ship, true)) # faction ship will aggro if you fire on them	
	
	# research ship setup
	research_ship.name = "0_1_RESEARCHERS"
	research_ship.connect("set_beacon", $markers/research_ship_marker2.set_beacon)
	research_ship.set_beacon.emit(true)
	research_ship.set_aggro.emit(false)
	research_ship.connect("on_hit", _on_trigger_dialogue.bind(research_ship.name, "aggro"))
	research_ship.connect( "ship_destroyed", _on_trigger_dialogue.bind("YOU", "RESEARCHERS_KILLED") )
	
	# dialogue setup for all speaking npcs
	dialogue_setup([
		{ "ship": pirate_destroyer	, "init_dialogue": "greeting"},
		{ "ship": faction_ship		, "init_dialogue": "greeting"},
		{ "ship": research_ship		, "init_dialogue": "greeting"},
	])
	#endregion
	
	# finish with parent setup
	super._ready()
	start_next_objective()

func win_check() -> void:
	print("pirate ship died")
	dead_pirates += 1
	if dead_pirates >= to_kill.size():
		encounter_completed.emit(name)
	
func _on_encounter_completed(_name):
	super._on_encounter_completed(name)
	
	if is_instance_valid(faction_ship): queued_dialogue[faction_ship.name] = "win"
	if is_instance_valid(research_ship): queued_dialogue[research_ship.name] = "win"

func _on_trigger_dialogue(npc: String, cat: String = GET_QUEUED_DIALOGUE) -> void:
	super._on_trigger_dialogue(npc, cat)
	
	if not won and not spoke_to_researchers:
		if research_ship and npc == research_ship.name:
			spoke_to_researchers = true
			dialouge_runner.dialogue_completed.connect(start_next_objective, CONNECT_ONE_SHOT)
