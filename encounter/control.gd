extends Control

@export var sector_b: Area2D
@export var player: TestShip
@export var npc_ship: TestShip

@onready var location_dropdown = $VBoxContainer/LocationContainer/LocationDropdown
@onready var item_dropdown = $VBoxContainer/ItemContainer/ItemDropdown
@onready var result_label = $VBoxContainer/ResultLabel
@onready var confirm_button = $VBoxContainer/ConfirmButton

var selected_location = ""
var selected_ship_type = ""

func _ready():
	# location dropdown
	var locations = EncounterData.encounter_dictionary.keys()
	for loc in locations:
		location_dropdown.add_item(loc)
		
	# item dropdown
	for item in EncounterData.item_keys:
		item_dropdown.add_item(item)
	
	# signals
	location_dropdown.item_selected.connect(_on_location_selected)
	item_dropdown.item_selected.connect(_on_item_selected)
	confirm_button.pressed.connect(_on_confirm_pressed)
	
	# default to first vals
	_on_location_selected(0);
	
	# prevent sticky focus
	confirm_button.focus_mode = Control.FOCUS_NONE

func _on_location_selected(index):
	selected_location = location_dropdown.get_item_text(index)
	update_result()

# TODO: check that this is actually updating player state
func _on_item_selected(index):
	var item = item_dropdown.get_item_text(index)
	player.state.items.push(item)
	update_result()

func update_result():
	if selected_location == "" or selected_ship_type == "":
		result_label.text = "select location and ship type"
		return
	
	var event_id = EncounterData.get_event_id(selected_location, selected_ship_type)
	var description = EncounterData.get_encounter_description(selected_location, selected_ship_type)
	
	result_label.text = "event ID: %d\n%s" % [event_id, description]
	
func _on_confirm_pressed():
	if selected_location == "" or selected_ship_type == "":
		print("[SELECTOR] select both location and ship type")
		return
	
	if not sector_b or not npc_ship:
		print("[SELECTOR] missing sector_b or npc_ship reference")
		return
	
	var location_val = EncounterData.locations[selected_location]
	var ship_val = EncounterData.ship_types[selected_ship_type]
	var event_id = location_val * 10 + ship_val
	var description = EncounterData.encounters.get(event_id, "DEFAULT")
	
	# apply sector metadata
	sector_b.set_meta("location_type", selected_location)
	sector_b.set_meta("location_value", location_val)
	
	# apply npc metadata
	npc_ship.set_meta("ship_type", selected_ship_type)
	npc_ship.set_meta("ship_value", ship_val)
	npc_ship.update_type_label()

	print("[SELECTOR] CONFIRMED ENCOUNTER:")
	print("  location: ", selected_location)
	print("  ship type: ", selected_ship_type)
	print("  event ID: ", event_id)
	print("  description: ", description)
