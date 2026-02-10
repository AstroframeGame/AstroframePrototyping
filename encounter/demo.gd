extends Node2D

@export var sector_a: Area2D
@export var sector_b: Area2D
@export var npc_ship: TestShip
@export var player: Node

var encounter_manager: EncounterManager
var player_state: PlayerState

func _ready() -> void:
	encounter_manager = EncounterManager.new()
	add_child(encounter_manager)
	
	player_state = player.get_node("StateManager")
		
	# sectors signals
	if sector_a:
		sector_a.body_entered.connect(_on_sector_a_entered)
	if sector_b:
		sector_b.body_entered.connect(_on_sector_b_entered)

func _on_sector_a_entered(body: Node) -> void:
	if body == player:
		#print("[INFO] player entered sector A")
		pass

# TODO: fix
# with PlayerSystem, not detecting enter
func _on_sector_b_entered(body: Node) -> void:
	if body == player:
		#print("[INFO] player entered sector B")
		var loc = sector_b.get_meta("location_key")
		if(!loc): return
		
		# move to new location (assuming no nested locations for now)
		var from = ""
		if(player_state.location.size() > 0):
			from = player_state.location[0]
		player_state.change_location(loc, from)
		encounter_manager.try_spawn(loc, player, player_state)
