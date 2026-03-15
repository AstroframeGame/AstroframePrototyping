class_name HexEditor
extends Node

enum Mode { VIEW, ADD, MOVE, DESTROY }

@onready var ship: Ship = $"../Ship"
@onready var mode_dropdown: OptionButton = $"../UI/ModeDropdown"
@onready var room_picker: Node = $"../UI/TabContainer/RoomPicker"

var preview_instance: Room
var current_rotation: int = 0
var current_mode: Mode = Mode.VIEW
var undo: UndoRedo = UndoRedo.new()
var _prefab_index: int = -1

signal on_room_add()
signal on_room_destroy()

func _ready() -> void:
	room_picker.on_clicked.connect(_on_room_prefab_selected)
	mode_dropdown.item_selected.connect(_on_mode_selected)
	ship.room_clicked.connect(_on_ship_room_clicked)
	undo.max_steps = 10
	on_room_add.emit()

func _process(_delta: float) -> void:
	if current_mode == Mode.ADD and preview_instance:
		preview_instance.visible = true
		_update_preview()
	elif preview_instance:
		preview_instance.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("editor_redo"):
		undo.redo()
		return
	if event.is_action_pressed("editor_undo"):
		undo.undo()
		return
		
	if current_mode == Mode.ADD and event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var cell = ship.world_to_grid(ship.get_global_mouse_position())
			_attempt_place(cell)
			return
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			return
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_rotate_preview(-1)
			return
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_rotate_preview(1)
			return

func _get_prefab() -> PackedScene:
	if _prefab_index < 0: return null
	return room_picker.room_prefabs[_prefab_index]

func _rotate_preview(direction: int) -> void:
	current_rotation = (current_rotation + direction) % 6
	if current_rotation < 0: current_rotation += 6

func _update_preview() -> void:
	var cell = ship.world_to_grid(ship.get_global_mouse_position())
	preview_instance.global_position = ship.grid_to_world(cell)
	preview_instance.global_rotation = ship.global_rotation + (current_rotation * PI / 3.0)
	
	var cells = ship.get_cells_for_room(preview_instance, cell, current_rotation)
	var is_free = ship.is_area_free(cells)
	var is_adj = ship.is_adjacent_to_occupied(cells)
	var is_valid = is_free and is_adj
	
	var color = Color(0, 1, 0, 0.5) if is_valid else Color(1, 0, 0, 0.5)
	for child in preview_instance.get_children():
		if "modulate" in child:
			child.modulate = color

func _attempt_place(cell: Vector2i) -> void:
	if not preview_instance: return
	var cells = ship.get_cells_for_room(preview_instance, cell, current_rotation)
	if not ship.is_area_free(cells) or not ship.is_adjacent_to_occupied(cells): 
		return

	var prefab = _get_prefab()
	var new_room = prefab.instantiate() as Room
	
	undo.create_action("Place Room")
	undo.add_do_method(ship.add_room.bind(new_room, cell, current_rotation))
	undo.add_do_reference(new_room)
	undo.add_undo_method(ship.remove_room.bind(new_room))
	undo.commit_action()
	on_room_add.emit()

func _attempt_destroy(room: Room) -> void:
	var cell = ship.world_to_grid(room.global_position)
	var rot = int(round(room.rotation / (PI / 3.0)))
	
	undo.create_action("Remove Room")
	undo.add_do_method(ship.remove_room.bind(room))
	undo.add_undo_method(ship.add_room.bind(room, cell, rot))
	undo.add_undo_reference(room)
	undo.commit_action()
	on_room_destroy.emit()

func _on_room_prefab_selected(index: int) -> void:
	_prefab_index = index
	current_mode = Mode.ADD
	mode_dropdown.selected = Mode.ADD
	
	if preview_instance:
		preview_instance.queue_free()
	
	var prefab = _get_prefab()
	if prefab:
		preview_instance = prefab.instantiate() as Room
		preview_instance.name = "PREVIEW" + preview_instance.name
		add_child(preview_instance)
		_rotate_preview(0)

func _on_ship_room_clicked(room: Node, button_index: int) -> void:
	if button_index != MOUSE_BUTTON_LEFT: return

	if current_mode == Mode.DESTROY:
		_attempt_destroy(room)
	elif current_mode == Mode.MOVE:
		_prefab_index = room_picker.get_room_index(room)
		_on_room_prefab_selected(_prefab_index)
		_attempt_destroy(room)

func _on_mode_selected(index: int) -> void:
	current_mode = index as Mode
