extends Node

@onready var save_manager: EditorSaveManager = $"../../../SaveManager"
var ship: Ship :
	get:
		return save_manager.ship

func _ready() -> void:
	$VBoxContainer/HBoxContainer2/ShipName.text_submitted.connect(set_ship_name)
	$VBoxContainer/HBoxContainer/CheckBox.toggled.connect(set_custom_color_toggle)
	$VBoxContainer/HBoxContainer/ColorPickerButton.color_changed.connect(set_custom_color)
	$VBoxContainer/HBoxContainer3/OptionButton.item_selected.connect(set_team)
	save_manager.on_post_load.connect(on_load)

func on_load():
	$VBoxContainer/HBoxContainer2/ShipName.text = ship.name

func set_ship_name(text : String):
	ship.name = text
	
func set_custom_color_toggle(toggled : bool):
	pass
	
func set_custom_color(color : Color):
	pass
	
func set_team(team : int):
	pass
