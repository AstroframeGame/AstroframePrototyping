extends Node

@onready var hex_editor: HexEditor = $"../../../HexEditor"
@onready var save_manager: EditorSaveManager = $"../../../SaveManager"
var ship: Ship :
	get:
		return save_manager.ship

func _ready() -> void:
	$VBoxContainer/HBoxContainer2/ShipName.text_submitted.connect(set_ship_name)
	$VBoxContainer/HBoxContainer/CheckBox.toggled.connect(set_custom_color_toggle)
	$VBoxContainer/HBoxContainer/ColorPickerButton.color_changed.connect(set_custom_color)
	$VBoxContainer/HBoxContainer3/OptionButton.item_selected.connect(set_team)
	$VBoxContainer/HBoxContainer4/CheckBox.toggled.connect(show_exterior)
	
	save_manager.on_post_load.connect(on_load)
	var refresh = func (): show_exterior($VBoxContainer/HBoxContainer4/CheckBox.button_pressed)
	hex_editor.on_room_add.connect(refresh)
	hex_editor.on_room_destroy.connect(refresh)

func on_load():
	$VBoxContainer/HBoxContainer2/ShipName.text = ship.name
	
	$VBoxContainer/HBoxContainer4/CheckBox.button_pressed = false
	show_exterior(false)

func set_ship_name(text : String):
	ship.name = text
	
func set_custom_color_toggle(toggled : bool):
	print("Color toggled ", toggled)
	
func set_custom_color(color : Color):
	print("Color set ", color)
	
func set_team(team : int):
	print("Team set ", team)
	
func show_exterior(hide : bool):
	if ship != null:
		ship.set_exterior_visible(null, not hide)
