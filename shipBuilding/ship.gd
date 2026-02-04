class_name Ship
extends RigidBody2D

signal room_clicked(room: Room, button_index: int)

@onready var grid: TileMapLayer = $HexGrid
var occupied_cells: Dictionary = {}

func _ready() -> void:
	calc_center_of_mass()
	update_colliders()

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
	
func neighborhood_coords(cell: Vector2i) -> Array[Vector2i]:
	return [
		Vector2i(cell.x,cell.y-1), Vector2i(cell.x+1,cell.y-1), 
		Vector2i(cell.x-1,cell.y), Vector2i(cell.x+1,cell.y),
		Vector2i(cell.x,cell.y+1), Vector2i(cell.x+1,cell.y+1),
	]

func find_neightbors(room: Room) -> Array[Room]:
	# coords of a cell's neighbors : neighborCoords
	# { (x,y-1), (x+1,y-1), (x-1,y), (x+1,y), (x,y+1), (x+1,y+1), }
	var neighbors : Array[Room] = []
	grid = get_node("HexGrid")
	for cell in get_cells_for_room(room, room.grid_pos, room.rot_index):
		for coord in neighborhood_coords(cell):
			if is_area_free([coord]):
				print("find_neighbors found empty neighbor")
				continue
			var _room = occupied_cells[coord]
			if not _room in neighbors:
				neighbors.append(_room)
		#neighbors.erase(self)
	return neighbors
#endregion

#region Add and Remove Room
func add_room(room: Room, cell: Vector2i, rot_index: int) -> void:
	if room.get_parent() != self:
		add_child(room)
	
	room.global_position = grid_to_world(cell)
	room.rotation = rot_index * PI / 3.0
	
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


func update_colliders() -> void:
	var islands: Array[PackedVector2Array] = []
	var base_hex = _get_hex_poly()
	
	for child in get_children():
		if child is Room:
			var room = child
			var room_transform = room.transform
			
			for room_child in room.get_children():
				if room_child is Sprite2D:
					var poly = base_hex.duplicate()
					var sprite_pos = room_child.position
					
					for i in range(poly.size()):
						var point_in_room = sprite_pos + poly[i]
						poly[i] = room_transform * point_in_room
					
					var current_poly = poly
					var i = islands.size() - 1
					while i >= 0:
						var result = Geometry2D.merge_polygons(islands[i], current_poly)
						if result.size() == 1:
							current_poly = result[0]
							islands.remove_at(i)
						i -= 1
					islands.append(current_poly)

	var edge = get_node_or_null("Edge")
	if not edge:
		edge = CollisionPolygon2D.new()
		edge.name = "Edge"
		edge.build_mode = CollisionPolygon2D.BUILD_SEGMENTS
		add_child(edge)
		print("Fallback: ", name, " creating edge")
	var area = get_node_or_null("Ground")
	if not area:
		area = Area2D.new()
		area.name = "Ground"
		add_child(area)
		print("Fallback: ", name, " creating area")
	var solid = get_node_or_null("Ground/Solid")
	if not solid:
		solid = CollisionPolygon2D.new()
		solid.name = "Solid"
		edge.build_mode = CollisionPolygon2D.BUILD_SOLIDS
		area.add_child.call_deferred(solid)
		print("Fallback: ", name, " creating solid")
	
	if islands.size() > 0:
		edge.polygon = islands[0]
		solid.polygon = islands[0]
	else:
		edge.polygon = PackedVector2Array()
		solid.polygon = PackedVector2Array()

const HEX_WIDTH = 78
const HEX_HEIGHT = 90

func _get_hex_poly() -> PackedVector2Array:
	var w = HEX_WIDTH
	var h = HEX_HEIGHT
	var w_half = (w * 0.5) + 0.1
	var h_half = (h * 0.5) + 0.1
	var h_quarter = (h * 0.25) + 0.05
	
	return PackedVector2Array([
		Vector2(0, -h_half),
		Vector2(w_half, -h_quarter),
		Vector2(w_half, h_quarter),
		Vector2(0, h_half),
		Vector2(-w_half, h_quarter),
		Vector2(-w_half, -h_quarter)
	])
