class_name EditorSaveManager
extends Node

@onready var save_name: LineEdit = $"../UI/SaveLoad/SaveName"
@onready var ship: Ship = $"../Ship"
@onready var save_load: SaveLoad = $"../SaveLoad"
@onready var hex_editor: HexEditor = $"../HexEditor"

var save_path = "res://shipBuilding/ships/"
const ship_prefab = preload("res://shipBuilding/prefabs/ship.tscn")

func _ready() -> void:
	$"../UI/SaveLoad/Savetscn".pressed.connect(save_tscn)
	$"../UI/SaveLoad/Loadtscn".pressed.connect(load_tscn)
	$"../UI/SaveLoad/Savejson".pressed.connect(save_json)
	$"../UI/SaveLoad/Loadjson".pressed.connect(load_json)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("editor_save"):
		save_tscn()
	elif event.is_action_pressed("editor_open"):
		load_tscn()

func save_tscn() -> void:
	save_load.save_tscn(ship, save_path, save_name.text)

func load_tscn() -> void:
	var new_ship = save_load.load_tscn(save_path, save_name.text)
	if not new_ship:
		print("Load failed.")
		return
	_replace_ship(new_ship)

func save_json() -> void:
	save_load.save_json(ship, save_path, save_name.text)

func load_json() -> void:
	var new_ship = ship_prefab.instantiate()
	_replace_ship(new_ship)
	save_load.load_json(save_path, save_name.text, new_ship)

func _replace_ship(new_ship: Node) -> void:
	ship.get_parent().add_child(new_ship)
	new_ship.global_transform = ship.global_transform
	
	ship.queue_free()
	ship = new_ship
	
	hex_editor.ship = new_ship
