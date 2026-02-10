class_name Ship
extends RigidBody2D

signal room_clicked(room: Room, button_index: int)

const HEX_GRID_PREFAB = preload("res://shipBuilding/prefabs/hex_grid.tscn")
@onready var grid: TileMapLayer # set in update colliders
var occupied_cells: Dictionary[Vector2i, Room] = {} # only calculated in ship_building

@export var power_links : Dictionary[PowerOutHex, PowerInHex]

func _ready() -> void:
	update_colliders()
	calc_center_of_mass()
	update_occupied_cells()
	var ground : Area2D = $Ground
	ground.input_event.connect(ground_input_event)

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
func get_pilot() -> Player:
	var piloting :Piloting = get_piloting()
	if piloting:
		return piloting.seat.controlled_by
	return null

func handle_input(_event : InputEvent):
	#print_debug("input ship", event)
	pass
	
	power_hotkeys(_event)

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
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
	
	var goal_vel :Vector2 = Vector2.ZERO # default goal, for braking or auto braking
	
	if Input.is_action_pressed("brake"):
		pass
	elif direction.length() > 0.1: # directional input given
		if direction.y > 0:
			direction.y *= engines.forward_multiplier
		goal_vel = state.linear_velocity + direction.rotated(global_rotation)
		goal_vel = goal_vel.normalized() * min(goal_vel.length(), engines.get_max_speed()) # clamp speed
	state.linear_velocity = lerp(state.linear_velocity, goal_vel, engines.get_thrust() * delta)

# THIS SHOULD BE IN THE INPUT SINGLETON
var mouse_controller = "mouse"
func _input(event)-> void:
	if event is InputEventMouseMotion:
		if event.relative.length() > 1:
			mouse_controller = "mouse"
	var look_dir_controller = Input.get_vector("ship_look_left","ship_look_right", "ship_look_down", "ship_look_up")
	if look_dir_controller.length() > 0.1:
		mouse_controller = "controller"

const flight_deadzone = 30 #px
func rotate_ship(state: PhysicsDirectBodyState2D):
	var engines :Engines = get_engines()
	var piloting : Piloting = get_piloting()
	var pilot : Player = get_pilot()
	if not engines or not piloting:
		return
	if not pilot:
		state.angular_velocity = 0
		return
	var center = get_viewport_rect().get_center()
	var look_dir = get_viewport().get_mouse_position() - center
	if look_dir.abs().x < 30:
		look_dir = Vector2.ZERO
	else:
		look_dir.x -= flight_deadzone * sign(look_dir.x) 
	# JITTER
	#var target_angle = look_dir.angle() + PI/2
	#var angle_delta = wrapf(target_angle - global_rotation, -PI, PI)
	var rot_amount = look_dir.x * 0.01
	if mouse_controller == "controller":
		rot_amount = Input.get_axis("ship_look_left","ship_look_right")
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
		edge.build_mode = CollisionPolygon2D.BUILD_SEGMENTS
		print("Fallback: ", name, " creating edge")
	var area = get_node_or_null("Ground")
	if not area:
		area = Area2D.new()
		add_child(area)
		area.name = "Ground"
		print("Fallback: ", name, " creating area")
	var solid = get_node_or_null("Ground/Solid")
	if not solid:
		solid = CollisionPolygon2D.new()
		solid.name = "Solid"
		solid.build_mode = CollisionPolygon2D.BUILD_SOLIDS
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
#endregion

#region Power
func get_avalible_power_out() -> Array[PowerOutHex]:
	var out : Array[PowerOutHex] = []
	for r in get_children():
		if r is Room:
			for h in r.get_out_hexes():
				if not h.is_powering:
					out.append(h)
	print(out)
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
			add_power_link_next(power_hex)

func add_power_link_next(power_in : PowerInHex) -> bool:
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

func add_power_room(room : Room, subtract : bool = false):
	if not room:
		return
	var hexes = room.get_in_hexes()
	if not subtract:
		for h in hexes:
			if h.is_powered:
				remove_power_link_in(h)
				return
	else:
		for h in hexes:
			if not h.is_powered:
				add_power_link_next(h)
				return
	
func power_hotkeys(event : InputEvent):
	var add = true
	if Input.is_action_pressed("ship_power_depower"):
		add = false
	
	if Input.is_action_just_pressed("ship_power_shields"):
		var r = get_room_class("Shields")
		add_power_room(r, add)
	if Input.is_action_just_pressed("ship_power_engines"):
		var r = get_room_class("Engines")
		add_power_room(r, add)
	if Input.is_action_just_pressed("ship_power_sensors"):
		var r = get_room_class("Sensors")
		add_power_room(r, add)
	
# use the class name as a string
func get_room_class(class_type : String):
	for r in get_children():
		if r.get_script():
			if r.get_script().get_global_name() == class_type:
				return r
	return null
#endregion
