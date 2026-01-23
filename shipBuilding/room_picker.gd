extends Node

var rooms_path = "res://shipBuilding/rooms/"
var room_prefabs : Array[PackedScene] # autofills from the rooms folder.

var button_prefab = preload("res://shipBuilding/prefabs/room_button.tscn")
@onready var button_parent: VBoxContainer = $ScrollContainer/VBoxContainer

signal on_clicked(prefab_index : int)

func _ready() -> void:
	load_rooms()
	create_room_buttons()

func get_room_index(room_instance : Room) -> int:
	for i in range(room_prefabs.size()):
		if room_instance.scene_file_path == room_prefabs[i].resource_path:
			return i
	return -1

func load_rooms() -> void:
	var dir = DirAccess.open(rooms_path)
	if not dir:
		push_error("Failed to access directory: " + rooms_path)
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if !dir.current_is_dir() and (file_name.ends_with(".tscn") or file_name.ends_with(".scn")):
			var full_path = rooms_path.path_join(file_name)
			var scene = load(full_path)
			if scene is PackedScene:
				room_prefabs.append(scene)
		file_name = dir.get_next()
	dir.list_dir_end()

func create_room_buttons() -> void:
	for i in room_prefabs.size():
		var button = button_prefab.instantiate()
		button_parent.add_child(button)
		
		var room = room_prefabs[i].instantiate()
		button.get_node("RoomContainer").add_child(room)
		button.get_node("Name").text = room.name
		button.pressed.connect(func(): on_clicked.emit(i))
