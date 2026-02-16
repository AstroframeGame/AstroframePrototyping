extends Node2D

@export var faction_ship: Node
@export var pirate_destroyer: Node

var player: Node
var inRange: bool = false

signal trigger_dialogue(npc: String, cat: String)

func _ready() -> void:
	# set npc metadata 
	faction_ship.name = "A_1_FACTION_PATROL"
	pirate_destroyer.name = "A_1_PIRATE_DESTROYER"
	
func _process(delta: float) -> void:
	if not player:
		player = get_parent().multiplayer_manager.my_player
	
	if player.global_position.distance_to(faction_ship.global_position) < 1000:
			trigger_dialogue.emit(faction_ship.name, "greeting")
	elif player.global_position.distance_to(pirate_destroyer.global_position) < 1000:
			trigger_dialogue.emit(pirate_destroyer.name, "greeting")
	pass

func start_dialogue(npc: String, cat: String)->void:
	#print(get_tree().root.get_node("Hub").get_node("GameManager"))
	var gm : GameManager = get_tree().root.get_node("Hub").get_node("GameManager")
	#print(gm.dialogue_runner)
	var dialouge_runner : DialougeRunner = gm.dialogue_runner
	
	var dialouge = BarkGetter.retrieve(npc, cat)
	if dialouge:
		dialouge_runner.start(dialouge)
