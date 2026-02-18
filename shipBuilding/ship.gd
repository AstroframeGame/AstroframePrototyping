class_name Ship
extends RigidBody2D

signal room_clicked(room: Room, button_index: int)
signal on_airlock_interaction(is_inside : bool)

const HEX_GRID_PREFAB = preload("res://shipBuilding/prefabs/hex_grid.tscn")
@onready var grid: TileMapLayer # set in update colliders
var occupied_cells: Dictionary[Vector2i, Room] = {} # only calculated in ship_building

@export var power_links : Dictionary[PowerOutHex, PowerInHex]

@export var max_hit_points : int = 0
@export var hit_points : int = 0

@export var hud : CanvasLayer = null

func _ready() -> void:
	update_colliders()
	calc_center_of_mass()
	update_occupied_cells()
	
	for child in get_children():
		if child is Room:
			max_hit_points += child.durability
	hit_points = max_hit_points
	hud = get_node_or_null("HUD")
	if hud:
		hud.initialize()
	z_index = 1

func ground_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		var cell = world_to_grid(get_global_mouse_position())
		if occupied_cells.has(cell):
			var room = occupied_cells[cell]
			print("Room ", room, " was clicked")
			room_clicked.emit(room, event.button_index)

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
func get_pilot() -> PlayerCharacter:
	var piloting :Piloting = get_piloting()
	if piloting:
		return piloting.seat.controlled_by
	return null
func get_cannons() -> Array[Cannon]:
	var cannons : Array[Cannon]
	for r in get_children():
		if r is Cannon:
			cannons.append(r)
	return cannons

func handle_input(_event : InputEvent):
	#print_debug("input ship", event)
	pass

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	rotate_ship(state)
	move_ship(state)

func move_ship(state: PhysicsDirectBodyState2D):
	var engines :Engines = get_engines()
	var pilot : PlayerCharacter = get_pilot()
	if not engines:
		return
	if not pilot:
		state.linear_velocity = Vector2.ZERO
		return
	var direction = Input.get_vector("left", "right", "up", "down")
	var delta = get_process_delta_time()
	
	var goal_vel :Vector2 = Vector2.ZERO # default goal, for braking or auto braking
	
	if direction.length() > 0.1 or Input.is_action_pressed("brake"): # directional input given
		if direction.y > 0:
			direction.y *= engines.forward_multiplier
		goal_vel = state.linear_velocity + direction.rotated(global_rotation)
		goal_vel = goal_vel.normalized() * min(goal_vel.length(), engines.get_max_speed()) # clamp speed
		state.linear_velocity = lerp(state.linear_velocity, goal_vel, engines.get_thrust() * delta)
	else:
		state.linear_velocity = lerp(state.linear_velocity, goal_vel, engines.get_thrust() * engines.drag_multiplier * delta)


const flight_deadzone = 0.05 #screen %
func rotate_ship(state: PhysicsDirectBodyState2D):
	var engines :Engines = get_engines()
	var piloting : Piloting = get_piloting()
	var pilot : PlayerCharacter = get_pilot()
	if not engines or not piloting:
		return
	if not pilot:
		state.angular_velocity = 0
		return
	var look_dir = InputHelper.mouse_center_offset_deadzone(flight_deadzone)
	var rot_amount = look_dir.x * 0.01
	if not InputHelper.using_mouse:
		rot_amount = InputHelper.controller_look.x
	state.angular_velocity = rot_amount * engines.get_rotational_thrust()
	
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

func get_bounds_rect() -> Rect2:
	var combined_rect = Rect2()
	for c in get_children():
		if c is CollisionPolygon2D:
			var global_child_rect = c.global_transform * polygon_rect(c)
			if combined_rect == Rect2():
				combined_rect = global_child_rect
			else:
				combined_rect = combined_rect.merge(global_child_rect)
	return combined_rect * global_transform.inverse()

func polygon_rect(c : CollisionPolygon2D):
	var points = c.polygon
	if points.size() > 0:
		var min_x = points[0].x
		var min_y = points[0].y
		var max_x = points[0].x
		var max_y = points[0].y
		
		for p in points:
			min_x = min(min_x, p.x)
			min_y = min(min_y, p.y)
			max_x = max(max_x, p.x)
			max_y = max(max_y, p.y)
		
		var size = Vector2(max_x - min_x, max_y - min_y)
		var rect = Rect2(Vector2(min_x, min_y), size)
		
		#rect.position += c.global_position
		return rect
	return Rect2(0,0,0,0)

#endregion

#region Grid and Cell functions
func update_occupied_cells()->void:
	for room in get_children():
		if room is Room:
			add_room(room, room.grid_pos, room.rot_index)

func world_to_grid(world_pos: Vector2) -> Vector2i:
	return $HexGrid.local_to_map(to_local(world_pos))
	
func grid_to_world(cell: Vector2i) -> Vector2:
	return to_global($HexGrid.map_to_local(cell))

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
	grid = get_node("HexGrid")
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

func is_adjacent_to_occupied(cells: Array[Vector2i]) -> bool:
	if occupied_cells.is_empty():
		return true
	
	var grid_layer: TileMapLayer = $HexGrid
	var pointy_sides = [
		TileSet.CELL_NEIGHBOR_RIGHT_SIDE,
		TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_SIDE,
		TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_SIDE,
		TileSet.CELL_NEIGHBOR_LEFT_SIDE,
		TileSet.CELL_NEIGHBOR_TOP_LEFT_SIDE,
		TileSet.CELL_NEIGHBOR_TOP_RIGHT_SIDE
	]
	
	for cell in cells:
		for side in pointy_sides:
			var neighbor = grid_layer.get_neighbor_cell(cell, side)
			if occupied_cells.has(neighbor):
				return true
	return false
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
	
	update_colliders()
	calc_center_of_mass()

func remove_room(room: Room) -> void:
	var keys_to_erase = []
	for cell in occupied_cells:
		if occupied_cells[cell] == room:
			keys_to_erase.append(cell)
			
	for k in keys_to_erase:
		occupied_cells.erase(k)
	
	remove_child(room)
	
	update_colliders()
	calc_center_of_mass()

#endregion

#region Collisions
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
	
	grid = get_node_or_null("HexGrid")
	if not grid:
		grid = HEX_GRID_PREFAB.instantiate()
		add_child(grid)
	
	var edge = get_node_or_null("Edge")
	if not edge:
		edge = CollisionPolygon2D.new()
		add_child(edge)
		edge.name = "Edge"
		edge.owner = self
		edge.build_mode = CollisionPolygon2D.BUILD_SEGMENTS
		print("Fallback: ", name, " creating edge")
	var area = get_node_or_null("Ground")
	if not area:
		area = Area2D.new()
		add_child(area)
		area.name = "Ground"
		area.owner = self
		print("Fallback: ", name, " creating area")
	var solid = get_node_or_null("Ground/Solid")
	if not solid:
		solid = CollisionPolygon2D.new()
		solid.name = "Solid"
		solid.build_mode = CollisionPolygon2D.BUILD_SOLIDS
		area.add_child(solid)
		solid.owner = self
		print("Fallback: ", name, " creating solid")
	
	move_child.call_deferred(edge, -1)
	move_child.call_deferred(area, -1)
	
	if islands.size() > 0:
		edge.polygon = islands[0]
		solid.polygon = islands[0]
	else:
		edge.polygon = PackedVector2Array()
		solid.polygon = PackedVector2Array()
	
	
	area.input_pickable = true
	if not area.input_event.is_connected(ground_input_event):
		area.input_event.connect(ground_input_event)

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
#endregion

#region Power
func get_avalible_power_out() -> Array[PowerOutHex]:
	var out : Array[PowerOutHex] = []
	for r in get_children():
		if r is Room:
			for h in r.get_out_hexes():
				if not h.is_powering:
					out.append(h)
	return out

func toggle_power(power_hex):
	if power_hex is PowerOutHex && power_hex.is_powering:
		# turn off power
		remove_power_link_out(power_hex)
	if power_hex is PowerInHex:
		if power_hex.is_powered:
			# turn off power
			remove_power_link_in(power_hex)
		else:
			# turn on power
			set_next_avalible_power_out(power_hex)

func set_next_avalible_power_out(power_in : PowerInHex) -> bool:
	var power_outs = get_avalible_power_out()
	if power_outs.size() > 0:
		var power_out = power_outs[0]
		add_power_link(power_out, power_in)
		return true
	return false

func add_power_link(power_out : PowerOutHex, power_in : PowerInHex):
	if power_out.is_powering or power_in.is_powered:
		return false
	power_links[power_out] = power_in
	power_out.update_state(true)
	power_in.update_state(true)
	power_in.room.on_power_level_change.emit(power_in)
	return true

func remove_power_link_in(power_in : PowerInHex):
	var power_out = power_links.find_key(power_in)
	if power_out != null:
		power_links.erase(power_out)
		power_out.update_state(false)
		power_in.update_state(false)
		power_in.room.on_power_level_change.emit(power_in)
		return true
	return false

func remove_power_link_out(power_out : PowerOutHex):
	if power_out != null && power_links.has(power_out):
		var power_in = power_links[power_out]
		power_links.erase(power_out)
		power_out.update_state(false)
		power_in.update_state(false)
		power_in.room.on_power_level_change.emit(power_in)
		return true
	return false
#endregion

#region Health	
func take_damage(amount:int):
	hit_points -= amount
	hud.update_hp_bar()

# death check
func _process(_delta: float) -> void:
	if hit_points > 0:
		return 
	# relocate player if its in the ship
	for child in get_children():
		if child.name == "PlayerSystem":
			child.reparent(get_parent())
			for node in child.get_children():
				if node is PlayerCharacter:
					node.on_ship_exit()
					break
			break
	queue_free()

#endregion

#region InteriorExterior


# DO NOT SYNC
var _my_player_within : bool = false
var my_player_within : bool:
	set(value):
		set_rooms_visible(value)
		_my_player_within = false
	get:
		return _my_player_within
# this is used to determin whether or not to show the ship's roof

# this should maybe become generic for enemies too?
func on_character_enter_ship(_p : PlayerCharacter):
	# if I am MultiplayerManager's my player
	my_player_within = true
	
func on_character_exit_ship(_p : PlayerCharacter):
	my_player_within = false

func set_rooms_visible(v : bool):
	for r in get_children():
		if r is Room:
			r.roof.visible = v

#endregion
