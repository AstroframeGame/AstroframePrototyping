extends Control

@export var sector_b: Area2D
@export var player: Node
@export var npc_ship: TestShip

@onready var location_dropdown = $VBoxContainer/LocationContainer/LocationDropdown
@onready var item_dropdown = $VBoxContainer/ItemContainer/ItemDropdown
@onready var encounter_dropdown = $VBoxContainer/EncounterContainer/EncounterDropdown
@onready var result_label = $VBoxContainer/ResultLabel
@onready var confirm_button = $VBoxContainer/ConfirmButton

var selected_location = ""
var player_state: PlayerState
var encounter_manager: EncounterManager


func _ready():
	player_state = player.get_node("StateManager")	
	
	encounter_manager = EncounterManager.new()
	sector_b.add_child(encounter_manager)

	

	# location dropdown
	var locations = EncounterData.encounter_dictionary.keys()
	for loc in locations:
		location_dropdown.add_item(loc)
		
	for enc in EncounterData.encounter_keys:
		encounter_dropdown.add_item((enc))
		
	# item dropdown
	for item in EncounterData.item_keys:
		item_dropdown.add_item(item)
	
	# signals
	location_dropdown.item_selected.connect(_on_location_selected)
	item_dropdown.multi_selected.connect(get_items_selected)
	encounter_dropdown.multi_selected.connect(get_encounters_selected)
	confirm_button.pressed.connect(_on_confirm_pressed)
	
	# default to first vals
	_on_location_selected(0);
	
	# prevent sticky focus
	confirm_button.focus_mode = Control.FOCUS_NONE

func _on_location_selected(index):
	selected_location = location_dropdown.get_item_text(index)
	update_result()

func get_items_selected():
	var selected_indices = item_dropdown.get_selected_items()

	player_state.clear_inventory()
	for i in selected_indices:
		var item = item_dropdown.get_item_text(i)
		player_state.inventory_add(item)

func get_encounters_selected():
	var selected_indices = encounter_dropdown.get_selected_items()

	player_state.clear_encounters()
	for i in selected_indices:
		var enc = encounter_dropdown.get_item_text(i)
		player_state.complete_encounter(enc)

func update_result():
	if selected_location == "":
		result_label.text = "select location"
		return
	
	
func _on_confirm_pressed():
	get_items_selected() # get items
	#get_encounters_selected() # get encounters
	if selected_location == "":
		print("[SELECTOR] select location")
		return
	
	# apply sector metadata
	sector_b.set_meta("location_key", selected_location)
	
	### TEMP WORKAROUND
	# since sector/PlayerSystem needs debugging to detect enter, just going to 
	# 	force encounter start here
	var from = ""
	if(player_state.location.size() > 0):
		from = player_state.location[0]
	player_state.change_location(selected_location, from)
	encounter_manager.try_spawn(selected_location, player, player_state)
	###
