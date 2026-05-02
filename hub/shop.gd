extends Node2D
class_name Shop


func _ready() -> void:
	MenuManager.open_menu($Shop.get_path())

func generate():
	pass

func add_room_type(_room_id : String):
	pass
	# instantiate a "res://shipBuilding/prefabs/room_button.tscn"
	# instantiate the correct room like how res://shipBuilding/level_editor/room_picker.gd does it
