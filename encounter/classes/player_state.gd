class_name PlayerState

var inventory: Dictionary = {} # inventory
var completed_encounters: Array[String] = [] # progression tracking
var active_quests: Array[String] = []
var location: Array[String] = [] # holds tags from map position

### INVENTORY EDITS ###
func inventory_add(item: String) -> void:
	var inventory_slot = inventory.get(item)
	if(inventory_slot == null):
		inventory[item] = 0
	
	inventory[item] += 1 
	
func inventory_erase(item: String, amount: int = -1) -> void:
	if(inventory.get(item)):
		if(amount == -1): inventory.erase(item)
		else:
			# should be checking that this slot has enough to remove amount
			# TBD: do this here or before call??
			inventory[item] -= amount

func inventory_clear() -> void:
	for slot in inventory:
		inventory.erase(slot)

### ENCOUNTER EDITS ###
func complete_encounter(key: String):
	completed_encounters.push_back(key);

### LOCATION EDITS ###
func change_location(to: String = "", from: String = ""):
	var msg: String = ""
	
	if(to.length() > 0):
		if(!location.has(to)):
			location.push_front(to)
			msg += " to " + to
			
	if(from.length() > 0):
		if(location.has(from)):
			location.erase(from)
			msg += " from " + from
	
	if(msg.length() > 0):
		print("[STATE] Player moved%s." % msg)
