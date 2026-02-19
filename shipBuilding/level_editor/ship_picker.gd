extends Node

var ships_path = "res://shipBuilding/ships/"
var ship_prefabs: Array[PackedScene]

@onready var button_parent: VBoxContainer = $VBoxContainer
@onready var save_manager: EditorSaveManager = $"../../../SaveManager"

signal on_clicked(prefab_index: int)

func _ready() -> void:
	on_clicked.connect(func(index): save_manager._replace_ship(ship_prefabs[index].instantiate()))
	load_ships()

func load_ships() -> void:
	var dir = DirAccess.open(ships_path)
	if not dir: return
		
	for file_name in dir.get_files():
		var final_name = file_name.trim_suffix(".remap")
		if final_name.ends_with(".tscn") or final_name.ends_with(".scn"):
			var path = ships_path.path_join(final_name)
			ship_prefabs.append(load(path))
			_create_button(final_name.get_basename(), ship_prefabs.size() - 1)

func _create_button(label: String, index: int) -> void:
	var button = Button.new()
	button.text = label
	button.pressed.connect(func(): on_clicked.emit(index))
	button_parent.add_child(button)

func get_ship_index(ship_instance: Ship) -> int:
	for i in ship_prefabs.size():
		if ship_instance.scene_file_path == ship_prefabs[i].resource_path:
			return i
	return -1
