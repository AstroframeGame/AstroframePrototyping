extends TileMapLayer

enum Mode { VIEW, ADD, MOVE, DESTROY }

@onready var grid: TileMapLayer = $"."
@export var room_prefabs: Array[PackedScene]
@onready var ship: Ship = $"../Ship"
@onready var mode_dropdown: OptionButton = $"../UI/ModeDropdown"

var occupied_cells: Dictionary = {}
var current_index: int = 0
var preview_instance: Node2D
var base_pixel_offsets: Array[Vector2] = []
var current_rotation: int = 0
var current_mode: Mode = Mode.VIEW
var undo : UndoRedo = UndoRedo.new()

func _ready() -> void:
	mode_dropdown.item_selected.connect(_on_option_button_item_selected)
	ship.room_clicked.connect(_on_ship_room_clicked)
	_update_preview_shape()
	
	for child in ship.get_children():
		if child is Room:
			child.initialize(grid)
			for sprite in child.get_children():
				if sprite is Sprite2D:
					var global_pos = child.to_global(sprite.position)
					var cell = grid.local_to_map(grid.to_local(global_pos))
					occupied_cells[cell] = child

func _process(_delta: float) -> void:
	if current_mode == Mode.ADD and preview_instance:
		preview_instance.visible = true
		_update_preview_visuals()
	elif preview_instance:
		preview_instance.visible = false

func _unhandled_input(event: InputEvent) -> void:
	
	if event.is_action_pressed("editor_undo"):
		undo.undo()
		return
	if event.is_action_pressed("editor_redo"):
		undo.redo()
		return
		
	if current_mode != Mode.ADD: return
	
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var cell = grid.local_to_map(grid.to_local(get_global_mouse_position()))
			_attempt_place(cell)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_cycle_prefab()
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_rotate_prefab(-1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_rotate_prefab(1)

func _cycle_prefab() -> void:
	if room_prefabs.is_empty(): return
	current_index = (current_index + 1) % room_prefabs.size()
	_update_preview_shape()

func _rotate_prefab(direction: int) -> void:
	current_rotation = (current_rotation + direction) % 6
	if current_rotation < 0: current_rotation += 6
	
	if preview_instance:
		preview_instance.rotation = current_rotation * PI / 3.0

func _update_preview_shape() -> void:
	if preview_instance:
		preview_instance.queue_free()
		preview_instance = null
	
	base_pixel_offsets.clear()

	if room_prefabs.is_empty(): return

	preview_instance = room_prefabs[current_index].instantiate()
	add_child(preview_instance)
	
	for child in preview_instance.get_children():
		if child is Sprite2D:
			base_pixel_offsets.append(child.position)
	
	_rotate_prefab(0)

func get_occupied_cells(center_cell: Vector2i, rot_index: int) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var center_pos = grid.map_to_local(center_cell)
	var angle = rot_index * PI / 3.0
	
	for base_offset in base_pixel_offsets:
		var rotated_offset = base_offset.rotated(angle)
		var target_cell = grid.local_to_map(center_pos + rotated_offset)
		cells.append(target_cell)
		
	return cells

func _update_preview_visuals() -> void:
	if not preview_instance: return

	var center_cell = grid.local_to_map(grid.to_local(get_global_mouse_position()))
	preview_instance.position = grid.map_to_local(center_cell)
	
	var cells_to_check = get_occupied_cells(center_cell, current_rotation)
	var is_valid = true
	
	for cell in cells_to_check:
		if occupied_cells.has(cell):
			is_valid = false
			break
	
	var color = Color(0, 1, 0, 0.5) if is_valid else Color(1, 0, 0, 0.5)
	for child in preview_instance.get_children():
		if "modulate" in child:
			child.modulate = color

func _attempt_place(center_cell: Vector2i) -> void:
	if room_prefabs.is_empty(): return
	var cells_to_occupy = get_occupied_cells(center_cell, current_rotation)
	for cell in cells_to_occupy:
		if occupied_cells.has(cell):
			return

	var prefab = room_prefabs[current_index]
	var room_instance = prefab.instantiate() as Room
	
	#place_room(center_cell, current_rotation, cells_to_occupy)
	undo.create_action("Place Room")
	var _call_a = Callable(self, "ready")
	var call_do = Callable(self, "place_room")
	var call_undo = Callable(self, "_attempt_destroy")
	undo.add_do_method(call_do.bind(center_cell, current_rotation, room_instance))
	undo.add_do_reference(room_instance)
	undo.add_undo_method(call_undo.bind(room_instance))
	undo.commit_action()

func place_room(center_cell : Vector2i, rotation_index : int, room_instance : Room):
	print("Placing room")
	var cells_to_occupy = get_occupied_cells(center_cell, rotation_index)
	for cell in cells_to_occupy:
		if occupied_cells.has(cell):
			print_debug("Warning, could not place room")
			return
	
	var center_world_pos = grid.map_to_local(center_cell)

	#var room_instance = prefab.instantiate() as Room
	room_instance.initialize(grid)
	ship.add_child(room_instance)
	room_instance.position = center_world_pos
	room_instance.rotation = rotation_index * PI / 3.0
	
	for cell in cells_to_occupy:
		occupied_cells[cell] = room_instance

func _attempt_destroy(room: Room) -> void:
	print("destroying room ", room)
	if not room: return
	
	var cells_to_remove = []
	for cell in occupied_cells:
		if occupied_cells[cell] == room:
			cells_to_remove.append(cell)
	
	for cell in cells_to_remove:
		occupied_cells.erase(cell)
		
	room.queue_free()

func _attempt_move(room: Node) -> void:
	if not room: return
	
	for i in range(room_prefabs.size()):
		if room.scene_file_path == room_prefabs[i].resource_path:
			current_index = i
			break
			
	_update_preview_shape()
	_attempt_destroy(room)
	current_mode = Mode.ADD
	mode_dropdown.selected = Mode.ADD

func _on_option_button_item_selected(index: int) -> void:
	if index >= 0 and index <= 3:
		current_mode = index as Mode

func _on_ship_room_clicked(room: Node, button_index: int) -> void:
	if button_index != MOUSE_BUTTON_LEFT: return
	
	if current_mode == Mode.DESTROY:
		_attempt_destroy(room)
	elif current_mode == Mode.MOVE:
		_attempt_move(room)
