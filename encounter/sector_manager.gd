extends Node2D

@export var sector_a: Area2D
@export var sector_b: Area2D
@export var npc_ship: TestShip
@export var player_ship: TestShip

var encounter_manager: Encounter

func _ready() -> void:
	encounter_manager = Encounter.new()
	
	# sectors signals
	if sector_a:
		sector_a.body_entered.connect(_on_sector_a_entered)
	if sector_b:
		sector_b.body_entered.connect(_on_sector_b_entered)

func _on_sector_a_entered(body: Node2D) -> void:
	if body == player_ship:
		#print("[INFO] player entered sector A")
		pass

func _on_sector_b_entered(body: Node2D) -> void:
	if body == player_ship:
		#print("[INFO] player entered sector B")
		var loc = sector_b.get_meta("location_key")
		if(!loc): return
		
		# move to new location (assuming no nested locations for now)
		var from = ""
		if(player_ship.state.location.size() > 0):
			from = player_ship.state.location[0]
		player_ship.state.move(loc, from)
		encounter_manager.try_spawn(loc, player_ship.state)
