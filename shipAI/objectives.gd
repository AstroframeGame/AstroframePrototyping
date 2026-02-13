extends NinePatchRect

@onready var title_label : Label = $Title
@onready var content_label : Label = $Content

var ship_faction : String = ""
var ships_found_amount : int = 0
var ships_found_prompt : String:
	get:
		if ships_found_amount > 1:
			return "%s %s Ships Found" % [str(ships_found_amount), ship_faction]
		else:
			return "%s %s Ship Found" % [str(ships_found_amount), ship_faction]

func _ready() -> void:
	content_label.text = ships_found_prompt
	
func _process(_delta: float) -> void:
	var enemy_list : Array[Node] = get_tree().get_nodes_in_group("pirate_ship")
	ships_found_amount = enemy_list.size()
	ship_faction = "Pirate"
	content_label.text = ships_found_prompt

	if enemy_list.size() < 1:
		content_label.text = ""
