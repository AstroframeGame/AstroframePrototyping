extends Control

@export var sector_b: Area2D
@export var player: TestShip
@export var npc_ship: TestShip

@onready var location_dropdown = $VBoxContainer/LocationContainer/LocationDropdown
@onready var item_dropdown = $VBoxContainer/ItemContainer/ItemDropdown
@onready var result_label = $VBoxContainer/ResultLabel
@onready var confirm_button = $VBoxContainer/ConfirmButton

var selected_location = ""

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
	item_dropdown.multi_selected.connect(_on_multi_selected)
	confirm_button.pressed.connect(_on_confirm_pressed)
	
	# default to first vals
	_on_location_selected(0);
	
	# prevent sticky focus
	confirm_button.focus_mode = Control.FOCUS_NONE

func _on_location_selected(index):
	selected_location = location_dropdown.get_item_text(index)
	update_result()

# TODO: check that this is actually updating player state
func _on_multi_selected():
	var selected_indices = item_dropdown.get_selected_items()

	for i in selected_indices:
		var item = item_dropdown.get_item_text(i)
		player.state.push_to("inventory", item)

func update_result():
	if selected_location == "":
		result_label.text = "select location"
		return
	
	
func _on_confirm_pressed():
	_on_multi_selected() # get items
	if selected_location == "":
		print("[SELECTOR] select location")
		return
	
	# apply sector metadata
	sector_b.set_meta("location_key", selected_location)
