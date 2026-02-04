extends Node2D

@export var sector_a: Area2D
@export var sector_b: Area2D
@export var npc_ship: TestShip
@export var player_ship: TestShip

func _ready() -> void:
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
		
		var loc_encounters = EncounterData.encounter_dictionary[loc]
		if(loc_encounters):
			# check player state for encounter availability
			for key in loc_encounters:
				var encounter = loc_encounters[key]
				
				var reqs 
				if(encounter.has("requirements")):
					reqs = encounter.requirements
				
				# player must have required items
				if(reqs && reqs.has("items")):
					for item in reqs.items:
						print(player_ship.state)
						if(!player_ship.state.items.has(item)):
							print("player does not have %s" % item)
							return
							
				# player must have completed required encounters
				#if(reqs && reqs.has("encounters")):
					#for enc in reqs.encounters:
						## TODO: encounters should be recorded in world state, not player statee
						#if(!player_ship.state.items.has(enc)):
							#print("player does has not completed %s" % enc)
							#return
				
				# requirements checks passed --> start encounter!
				print("[SECTOR MANAGER]: Starting encounter %s" % key)
