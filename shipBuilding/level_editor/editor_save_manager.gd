class_name EditorSaveManager
extends Node

@onready var save_name: LineEdit = $"../UI/Options/SaveName"
@onready var ship: Ship = $"../Ship"
@onready var save_load: SaveLoad = $"../SaveLoad"
@onready var hex_editor: HexEditor = $"../HexEditor"

var save_path = "res://shipBuilding/ships/"
var in_game_path = "user://ships/"
const ship_prefab = preload("res://shipBuilding/prefabs/ship.tscn")

signal on_post_load()

func _ready() -> void:
	$"../UI/Options/HBoxContainer/Save/Savetscn".pressed.connect(save_tscn)
	$"../UI/Options/HBoxContainer/Save/Savejson".pressed.connect(save_json)
	$"../UI/Options/HBoxContainer/Load/Loadtscn".pressed.connect(load_tscn)
	$"../UI/Options/HBoxContainer/Load/Loadjson".pressed.connect(load_json)
	
	$"../UI/Options/HBoxContainer/Save/Savetscn".visible = "dev" in OS.get_cmdline_args()

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
	on_post_load.emit()

func save_json() -> void:
	var real_path = ProjectSettings.globalize_path(in_game_path)
	DirAccess.make_dir_recursive_absolute(real_path)
	save_load.save_json(ship, real_path, save_name.text)

func load_json() -> void:
	var new_ship = ship_prefab.instantiate()
	_replace_ship(new_ship)
	
	var real_path = ProjectSettings.globalize_path(in_game_path)
	DirAccess.make_dir_recursive_absolute(real_path)
	
	save_load.load_json(real_path, save_name.text, new_ship)
	on_post_load.emit()

func _replace_ship(new_ship: Node) -> void:
	ship.get_parent().add_child(new_ship)
	new_ship.global_transform = ship.global_transform
	
	ship.queue_free()
	ship = new_ship
	
	hex_editor.ship = new_ship
	hex_editor.ship.room_clicked.connect(hex_editor._on_ship_room_clicked)
