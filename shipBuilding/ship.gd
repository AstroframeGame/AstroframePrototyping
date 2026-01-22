class_name Ship
extends RigidBody2D

signal room_clicked(room: Room, button_index: int)

@onready var grid: TileMapLayer = $HexGrid

var occupied_cells: Dictionary = {}

func _input_event(_viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		var owner_id = shape_owner_get_owner(shape_find_owner(shape_idx))
		if owner_id and owner_id is Room:
			print("Room ", owner_id, " was clicked")
			room_clicked.emit(owner_id, event.button_index)

func world_to_grid(world_pos: Vector2) -> Vector2i:
	return grid.local_to_map(to_local(world_pos))

func grid_to_world(cell: Vector2i) -> Vector2:
	return to_global(grid.map_to_local(cell))

func is_area_free(cells: Array[Vector2i]) -> bool:
	for cell in cells:
		if occupied_cells.has(cell):
			return false
	return true

func get_cells_for_room(room: Node, center_cell: Vector2i, rot_index: int) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var center_local = grid.map_to_local(center_cell)
	var angle = rot_index * PI / 3.0
	
	for child in room.get_children():
		if child is Sprite2D:
			var rotated_offset = child.position.rotated(angle)
			var target_cell = grid.local_to_map(grid.to_local(to_global(center_local + rotated_offset)))
			cells.append(target_cell)
	return cells

func add_room(room: Room, cell: Vector2i, rot_index: int) -> void:
	if room.get_parent() != self:
		add_child(room)
	
	room.global_position = grid_to_world(cell)
	room.rotation = rot_index * PI / 3.0
	room.initialize(grid)
	
	var cells = get_cells_for_room(room, cell, rot_index)
	for c in cells:
		occupied_cells[c] = room

func remove_room(room: Room) -> void:
	var keys_to_erase = []
	for cell in occupied_cells:
		if occupied_cells[cell] == room:
			keys_to_erase.append(cell)
			
	for k in keys_to_erase:
		occupied_cells.erase(k)
	
	remove_child(room)

func update_colliders():
	pass
