extends Node

@onready var save_load: SaveLoad = $SaveLoad
var save_path = "res://shipBuilding/ships/"
@onready var save_name: LineEdit = $SaveName

# generic root ship
const ship_prefab = preload("res://shipBuilding/prefabs/ship.tscn")

func  _ready() -> void:
	$HBoxContainer/LoadJson.pressed.connect(load_json)
	$HBoxContainer/LoadTscn.pressed.connect(load_tscn)

func load_json() -> void:
	var new_ship = ship_prefab.instantiate()
	_add_ship(new_ship)
	save_load.load_json(save_path, save_name.text, new_ship)
	
func load_tscn() -> void:
	var new_ship = save_load.load_tscn(save_path, save_name.text)
	if not new_ship:
		print("Load failed.")
		return
	_add_ship(new_ship)
	
func _add_ship(new_ship: Ship) -> void:
	add_sibling(new_ship)
	new_ship.get_parent().move_child(new_ship,5)
	new_ship.global_position = $Target.global_position
	
