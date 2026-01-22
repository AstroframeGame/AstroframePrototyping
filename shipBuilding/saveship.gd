extends Node

@onready var save_name: LineEdit = $"../UI/SaveLoad/SaveName"
var save_path = "res://shipBuilding/ships/"
@onready var ship: Ship = $"../Ship"

const ship_prefab = preload("res://shipBuilding/prefabs/ship.tscn")

func _ready() -> void:
	# could have been done in editor, i just prefer code
	$"../UI/SaveLoad/Savetscn".pressed.connect(save_tscn)
	$"../UI/SaveLoad/Loadtscn".pressed.connect(load_tscn)
	$"../UI/SaveLoad/Savejson".pressed.connect(save_json)
	$"../UI/SaveLoad/Loadjson".pressed.connect(load_json)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("editor_save"):
		save_tscn()
		return
	if event.is_action_pressed("editor_open"):
		load_tscn()
		return

func save_tscn():
	var node = ship;
	
	# this is important for prefabing.
	for child in node.get_children(true):
		child.owner = node
		
	var packed_scene = PackedScene.new()
	var result = packed_scene.pack(node)
	
	if result == OK:
		var path = save_path + save_name.text + ".tscn"
		var error = ResourceSaver.save(packed_scene, path)
		if error == OK:
			print("Scene saved successfully!")
		else:
			print("Error saving scene: ", error)

func load_tscn():
	var path = save_path + save_name.text + ".tscn"
	if not ResourceLoader.exists(path):
		print_debug("Failed to open tscn at "+ path)
		return

	var new_ship = load(path).instantiate()
	ship.get_parent().add_child(new_ship)
	new_ship.global_transform = ship.global_transform
	
	ship.queue_free()
	ship = new_ship
	$"../HexEditor".ship = new_ship

func save_json() -> void:
	var data = {
		"name": ship.name,
		"rooms": []
	}
	
	for child in ship.get_children():
		if child is Room:
			var room_data = {}
			room_data["name"] = child.name
			if child.scene_file_path:
				room_data["id"] = child.scene_file_path.get_file().get_basename()
			else:
				push_warning("Room has no filename, skipping: " + child.name)
				continue
			
			var local_pos = ship.to_local(child.global_position)
			var grid_pos = ship.grid.local_to_map(local_pos)
			room_data["grid_pos"] = [grid_pos.x, grid_pos.y]
			
			var rot_index = int(round(child.rotation / (PI / 3.0))) % 6
			if rot_index < 0: rot_index += 6
			room_data["rot_index"] = rot_index
			
			data["rooms"].append(room_data)

	var json_string = JSON.stringify(data, "\t")
	var path = save_path + save_name.text + ".json"
	
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()
		print("Saved JSON to: " + path)
	else:
		push_error("Failed to save file: " + path)

func load_json() -> void:
	var path = save_path + save_name.text + ".json"
	
	if not FileAccess.file_exists(path):
		push_error("File not found: " + path)
		return
		
	var file = FileAccess.open(path, FileAccess.READ)
	var json_string = file.get_as_text()
	file.close()
	
	var data = JSON.parse_string(json_string)
	if data == null:
		push_error("Failed to parse JSON from: " + path)
		return
	
	var new_ship = ship_prefab.instantiate()
	ship.get_parent().add_child(new_ship)
	new_ship.global_transform = ship.global_transform
	
	if data.has("name"):
		ship.name = data["name"]
	
	if data.has("rooms"):
		for room_data in data["rooms"]:
			var id = room_data["id"]
			var prefab_path = "res://shipBuilding/rooms/" + id + ".tscn"
			
			if ResourceLoader.exists(prefab_path):
				var prefab = load(prefab_path)
				var room_instance = prefab.instantiate()
				
				room_instance.name = room_data["name"]
				
				var grid_array = room_data["grid_pos"]
				var cell = Vector2i(grid_array[0], grid_array[1])
				
				var rot_index = room_data["rot_index"]
				
				ship.add_room(room_instance, cell, rot_index)
			else:
				push_warning("Could not find room prefab: " + prefab_path)
				
	print("Loaded ship from: " + path)
