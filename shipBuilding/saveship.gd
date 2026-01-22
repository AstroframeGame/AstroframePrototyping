extends Node

@onready var save_name: LineEdit = $"../UI/SaveLoad/SaveName"
var save_path = "res://shipBuilding/ships/"


@onready var ship: Ship = $"../Ship"

func _ready() -> void:
	# could have been done in editor, i just prefer code
	$"../UI/SaveLoad/Savetscn".pressed.connect(save_tscn)

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
	var prefab = load("res://shipBuilding/ships/testShip.tscn")
	
	ship.queue_free()
	ship = prefab.instantiate()
	$"..".add_child(ship)
	# idk i havent tested, make sure that this works correctly with $"../HexGrid" and the editor
