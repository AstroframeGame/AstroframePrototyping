extends Node

@onready var save_name: LineEdit = $"../UI/SaveLoad/SaveName"
var save_path = "res://shipBuilding/ships/"


@onready var ship: Ship = $"../Ship"

func _ready() -> void:
	# could have been done in editor, i just prefer code
	$"../UI/SaveLoad/Savetscn".pressed.connect(save_tscn)
	$"../UI/SaveLoad/Loadtscn".pressed.connect(load_tscn)

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
