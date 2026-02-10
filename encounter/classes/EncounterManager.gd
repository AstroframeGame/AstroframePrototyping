extends Node
class_name EncounterManager

var encounter_scene = preload("res://encounter/Encounter.tscn")

# controls polling for and initializing encounters
# when player enters/exits a new location, trigger a search
# prioritize narrative arc
# then, check for non-narrative encounters (TBD -- lore building, PCG encounters)
func try_spawn(loc, player):
	var player_state = player.state
	var loc_encounters = EncounterData.encounter_dictionary[loc]
	if(loc_encounters):
		# check player state for encounter availability
		for key in loc_encounters:
			var encounter = loc_encounters[key]
			
			var reqs 
			if(encounter.has("requirements")):
				reqs = encounter.requirements
			
			var can_spawn = true
			# player must have completed required encounters
			if(reqs && reqs.has("encounters")):
				for enc in reqs.encounters:
					if(!player_state.completed_encounters.has(enc)):
						print("[ENCOUNTER MANAGER]: player has not completed %s" % enc)
						can_spawn = false
			
			# player must have required items
			if(reqs && reqs.has("items")):
				for item in reqs.items:
					print(player_state)
					if(!player_state.inventory.has(item)):
						print("[ENCOUNTER MANAGER]: player does not have %s" % item)
						can_spawn = false
			
			if !can_spawn: return
			
			# requirements checks passed --> start encounter!
			print("[ENCOUNTER MANAGER]: Starting encounter %s" % key)
			start_encounter(encounter, player)
			player_state.complete_encounter(key); # TEMP
			return key

	# no available encounters
	return

func start_encounter(encounter_data: Dictionary, player):
	var encounter = encounter_scene.instantiate()
	encounter.global_position = player.global_position
	add_child(encounter)
	
	# pass the encounter data to scene
	encounter.initialize(encounter_data)
