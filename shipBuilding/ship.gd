class_name Ship
extends RigidBody2D

signal room_clicked(room: Room, button_index: int)

@onready var grid: TileMapLayer = $HexGrid
var occupied_cells: Dictionary = {} # only calculated in ship_building

func _ready() -> void:
	calc_center_of_mass()
	# update occupied_cells
	for room in get_children():
		if room is Room:
			add_room(room, world_to_grid(room.global_position), room.rot_index)

# check if a room is clicked
func _input_event(_viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		var owner_id = shape_owner_get_owner(shape_find_owner(shape_idx))
		if owner_id and owner_id is Room:
			print("Room ", owner_id, " was clicked")
			room_clicked.emit(owner_id, event.button_index)

#region Piloting
func get_engines() -> Engines:
	for r in get_children():
		if r is Engines:
			return r
	return null
func get_piloting() -> Piloting:
	for r in get_children():
		if r is Piloting:
			return r
	return null
func get_pilot() -> Player:
	var piloting :Piloting = get_piloting()
	if piloting:
		return piloting.seat.controlled_by
	return null

func handle_input(_event : InputEvent):
	#print_debug("input ship", event)
	pass

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	#var piloting : Piloting = get_piloting()
	#if piloting and piloting.seat.controlled_by:
	rotate_ship(state)
	move_ship(state)

func move_ship(state: PhysicsDirectBodyState2D):
	var engines :Engines = get_engines()
	var pilot : Player = get_pilot()
	if not engines:
		return
	if not pilot:
		state.linear_velocity = Vector2.ZERO
		return
	var direction = Input.get_vector("left", "right", "up", "down")
	var delta = get_process_delta_time()
	if Input.is_action_pressed("brake"):
		state.linear_velocity -= state.linear_velocity.normalized() * engines.standard_thrust * delta
	else:
		state.linear_velocity += direction.rotated(global_rotation) * engines.standard_thrust * delta

func rotate_ship(state: PhysicsDirectBodyState2D):
	var engines :Engines = get_engines()
	var piloting : Piloting = get_piloting()
	var pilot : Player = get_pilot()
	if not engines or not piloting:
		return
	if not pilot:
		state.angular_velocity = 0
		return
	var center = piloting.global_position
	var look_dir = get_global_mouse_position() - center
	var target_angle = look_dir.angle() + PI/2
	var angle_delta = wrapf(target_angle - global_rotation, -PI, PI)
	state.angular_velocity = angle_delta * engines.rotational_thrust
	
func calc_center_of_mass():
	var hex_mass = 2.0
	var total_mass = 0.0
	
	for child in get_children():
		if child is Room:
			for hex in child.get_children():
				if hex is Sprite2D:
					total_mass += hex_mass
	if total_mass == 0:
		return
	mass = total_mass
#endregion

#region Grid and Cell functions
func world_to_grid(world_pos: Vector2) -> Vector2i:
	return $HexGrid.local_to_map(to_local(world_pos))
	
func grid_to_world(cell: Vector2i) -> Vector2:
	return to_global(grid.map_to_local(cell))

func is_area_free(cells: Array[Vector2i]) -> bool:
	for cell in cells:
		if occupied_cells.has(cell):
			return false
	return true

func get_cells_for_room(room: Node, center_cell: Vector2i, rot_index: int) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var center_local = $HexGrid.map_to_local(center_cell)
	var angle = rot_index * PI / 3.0
	
	for child in room.get_children():
		if child is Sprite2D:
			var rotated_offset = child.position.rotated(angle)
			var target_cell = $HexGrid.local_to_map($HexGrid.to_local(to_global(center_local + rotated_offset)))
			cells.append(target_cell)
	return cells
	
func neighborhood_coords(cell: Vector2i) -> Array[Vector2i]:
	return [
		Vector2i(cell.x-1,cell.y-1), Vector2i(cell.x,cell.y+1), 
		Vector2i(cell.x,cell.y-1), Vector2i(cell.x-1,cell.y+1),
		Vector2i(cell.x+1,cell.y), Vector2i(cell.x-1,cell.y),
	]
	# (-,-), (0,-), (+,0), (0,+), (-,+), (-,0)

func find_neighbors(room: Room) -> Array[Room]:
	var neighbors : Array[Room] = []
	for cell in get_cells_for_room(room, room.grid_pos, room.rot_index):
		for coord in neighborhood_coords(cell):
			if is_area_free([coord]):
				#print("find_neighbors found empty neighbor")
				continue
			var _room = occupied_cells[coord]
			if not _room in neighbors:
				neighbors.append(_room)
		#neighbors.erase(self)
	#print(neighbors)
	return neighbors
#endregion

#region Add and Remove Room
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
#endregion

func update_colliders():
	pass
