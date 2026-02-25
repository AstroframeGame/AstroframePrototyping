extends NinePatchRect

@onready var title : Label =  $Title
@onready var content : Label = $Content
var scanner_active: bool = true

var ships_found = {
	type = "",
	list = [],
	amount = 0
}

var ships_prompt : String:
	get:
		ships_found.amount = ships_found.list.size()
		if ships_found.amount == 1:
			return "%s Ship found" % [ships_found.type]
		if ships_found.amount == 0:
			return ""
		return "%d %s Ships found" % [ships_found.amount, ships_found.type]

func _ready() -> void:
	if not scanner_active: return
	content.text = ships_prompt

func _process(_delta: float) -> void:
	if not scanner_active: return
	ships_found.list = get_tree().get_nodes_in_group("pirate_ship")
	ships_found.type = "Pirate"
	content.text = ships_prompt
