class_name PlayerState

var inventory: Dictionary = {} # inventory
var completed_encounters: Dictionary = {} # progression tracking
var location: Array[String] = [] # holds tags from map position

func push_to(dictionary_name: String, item: String) -> void:
	var dictionary = self.get(dictionary_name)
	if(dictionary == null):
		print("[STATE]: Error! Dictionary '%s' does not exist." % dictionary_name)
		return
	
	var entry = dictionary.get(item)
	if(entry == null):
		dictionary[item] = 0
	
	dictionary[item] += 1 # blegghhh
	# TODO: might want to make a custom dictionary for state stuff
	# dictionary items could be lists or counts
	# some items should be unique, others can repreated (count increase)
	
func erase_from(dictionary_name: String, item: String) -> void:
	var dictionary = self.get(dictionary_name)
	if(!dictionary):
		print("[STATE]: Error! Dictionary '%s' does not exist." % dictionary_name)
		return
	if(dictionary.get(item)):
		dictionary.erase(item)	

func move(to: String = "", from: String = ""):
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
