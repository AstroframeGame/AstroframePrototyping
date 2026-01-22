class_name Ship
extends RigidBody2D

@onready var grid: TileMapLayer = $HexGrid

signal room_clicked(room: Room, button_index: int)

func _input_event(_viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		var owner_id = shape_owner_get_owner(shape_find_owner(shape_idx))
		print(owner_id)
		if owner_id and owner_id is Room:
			room_clicked.emit(owner_id, event.button_index)
