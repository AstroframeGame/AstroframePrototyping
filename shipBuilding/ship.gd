class_name Ship
extends RigidBody2D

signal room_clicked(room: Room, button_index: int)
signal on_airlock_interaction(interactor : PlayerCharacter, is_inside : bool) # called from airlock
signal ship_destroyed
signal on_hit()

const HEX_GRID_PREFAB = preload("res://shipBuilding/prefabs/hex_grid.tscn")
const HUD_PREFAB = preload("res://shipAI/prefabs/hud.tscn")
const SHIP_PREFAB = preload("res://shipBuilding/prefabs/ship.tscn")
const FLIGHT_DEADZONE = 0.05 # screen %
const MAX_MERGE_DISTANCE: float = 600.0
const HEX_WIDTH = 78
const HEX_HEIGHT = 90
const EDGE_WIDTH = 8.0

@onready var grid: TileMapLayer # set in update colliders
var occupied_cells: Dictionary[Vector2i, Room] = {}

@export var power_links : Dictionary[PowerOutHex, PowerInHex]

@export var max_hit_points : int = 0
@export var _hit_points : int = 0
@export var hud : ShipHud = null
var hit_points : int:
	get:
		return _hit_points
	set(value):
		if value < _hit_points:
			on_hit.emit()
		_hit_points = value


var merge_target_ship: Ship = null
var ghost_preview: Node2D = null

#region godot callbacks
func _ready() -> void:
	refresh_ship_state()
	
	on_airlock_interaction.connect(set_exterior_visible)
	on_hit.connect(hud.update_hp_bar)
	on_hit.connect(death_check)
	
	z_index = 1

func _process(_delta: float) -> void:
	# if not multiplayer auth: @Tapesh
	#   clear_ghost_preview()
	#   return
	var pushers = get_players_pushing()
	
	if pushers.is_empty() or process_room_detachment(pushers):
		clear_ghost_preview()
		return
		
	merge_target_ship = find_nearest_ship()
	
	if merge_target_ship:
		if not is_instance_valid(ghost_preview):
			generate_ghost_preview()
			
		var snap_data = merge_target_ship.calculate_snap_data(self)
		merge_target_ship.update_ghost_visuals(ghost_preview, snap_data)
		
		for p in pushers:
			if Input.is_action_just_pressed("interact") and snap_data.is_valid:
				merge_target_ship.apply_merged_rooms(self, snap_data)
				clear_ghost_preview()
				p.pushing = false
				p.fix_unsure_grounding()
				return
	else:
		clear_ghost_preview()

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	rotate_ship(state)
	move_ship(state)
#endregion

func ground_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		var cell = world_to_grid(get_global_mouse_position())
		if occupied_cells.has(cell):
			var room = occupied_cells[cell]
			#print("Room ", room, " was clicked")
			room_clicked.emit(room, event.button_index)

func refresh_ship_state() -> void:
	separate_islands()
	update_occupied_cells()
	update_colliders()
	calc_center_of_mass()
	check_hud()

#region Players
func _get_multiplayer_manager() -> MultiplayerManager:
	return get_tree().root.get_node_or_null("Hub/MultiplayerManager")

func get_players_from_manager() -> Array[PlayerCharacter]:
	var manager = _get_multiplayer_manager()
	return manager.players if manager else []

func my_character_inside() -> bool:
	var manager = get_tree().root.find_child("MultiplayerManager", true, false)
	return manager.my_player != null and manager.my_player.ship == self if manager else false
#endregion

#region Piloting
func get_engines() -> Engines:
	for r in get_children():
		if r is Engines:
			return r
	return null
func get_piloting() -> Piloting:
	for r in get_children():
		if r is Piloting and r.is_active():
			return r
	return null
func get_cannons() -> Array[Cannon]:
	var cannons : Array[Cannon] = []
	for r in get_children():
		if r is Cannon:
			cannons.append(r)
	return cannons

func _get_rotation_input() -> float:
	if InputHelper.using_mouse:
		return InputHelper.mouse_center_offset_deadzone(FLIGHT_DEADZONE).x * 0.01
	return InputHelper.controller_look.x

func handle_input(_event : InputEvent):
	#print_debug("input ship", event)
	pass

func move_ship(state: PhysicsDirectBodyState2D) -> void:
	var engines :Engines = get_engines()
	var piloting : Piloting = get_piloting()
	var delta : float = state.step

	if engines and piloting:
		var goal_vel = piloting.get_goal_velocity(state.linear_velocity)
		state.linear_velocity = lerp(state.linear_velocity, goal_vel, engines.get_thrust() * state.inverse_mass * delta)
	else:
		apply_push_velocity(state)
		return

func rotate_ship(state: PhysicsDirectBodyState2D) -> void:
	var engines : Engines = get_engines()
	var piloting : Piloting = get_piloting()
	
	if engines and piloting:
		state.angular_velocity = piloting.goal_angular_velocity()
	else:
		apply_push_rotation(state)

func calc_center_of_mass() -> void:
	var hex_mass = 2.0
	var total_mass = 0.0
	var weighted_pos_sum = Vector2.ZERO
	
	for child in get_children():
		if child is Room:
			for hex in child.get_children():
				if hex is Sprite2D:
					total_mass += hex_mass
					weighted_pos_sum += (child.transform * hex.position) * hex_mass
					
	if total_mass == 0:
		return
		
	mass = total_mass
	center_of_mass_mode = RigidBody2D.CENTER_OF_MASS_MODE_CUSTOM
	center_of_mass = weighted_pos_sum / total_mass

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
func update_occupied_cells() -> void:
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
		Vector2i(cell.x-1, cell.y-1), Vector2i(cell.x, cell.y+1), 
		Vector2i(cell.x, cell.y-1), Vector2i(cell.x-1, cell.y+1),
		Vector2i(cell.x+1, cell.y), Vector2i(cell.x-1, cell.y)
	]
	# (-,-), (0,-), (+,0), (0,+), (-,+), (-,0)

func find_neighbors(room: Room) -> Array[Room]:
	var neighbors: Array[Room] = []
	grid = get_node("HexGrid")
	for cell in get_cells_for_room(room, room.grid_pos, room.rot_index):
		for coord in neighborhood_coords(cell):
			if not is_area_free([coord]):
				var adj_room = occupied_cells[coord]
				if not adj_room in neighbors:
					neighbors.append(adj_room)
	return neighbors

func is_adjacent_to_occupied(cells: Array[Vector2i]) -> bool:
	if occupied_cells.is_empty():
		return true
	
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
			if occupied_cells.has(grid.get_neighbor_cell(cell, side)):
				return true
	return false
#endregion

#region Add and Remove Room

func add_room(room: Room, cell: Vector2i, rot_index: int) -> void:
	if room.get_parent() != self:
		add_child(room)
	
	room.global_position = grid_to_world(cell)
	room.rotation = rot_index * PI / 3.0
	
	for c in get_cells_for_room(room, cell, rot_index):
		occupied_cells[c] = room
		
	# add power links
	for hex in room.get_in_hexes():
		if not hex.on_clicked.is_connected(room.ship.toggle_power):
			hex.on_clicked.connect(room.ship.toggle_power)
		hex.update_state()
	for hex in room.get_out_hexes():
		hex.update_state()
	
	room.get_node("Roof").visible = not my_character_inside()

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
	
	for room in get_children():
		if room is Room:
			for room_child in room.get_children():
				if room_child is Sprite2D:
					var poly = base_hex.duplicate()
					for i in range(poly.size()):
						poly[i] = room.transform * (room_child.position + poly[i])
					
					var current_poly = poly
					var i = islands.size() - 1
					while i >= 0:
						var result = Geometry2D.merge_polygons(islands[i], current_poly)
						if result.size() == 1:
							current_poly = result[0]
							islands.remove_at(i)
						i -= 1
					islands.append(current_poly)
	
	if not get_node_or_null("HexGrid"):
		add_child(HEX_GRID_PREFAB.instantiate())
	
	var walls = get_node_or_null("Walls")
	if not walls:
		walls = StaticBody2D.new()
		walls.name = "Walls"
		add_child(walls)
	
	for child in walls.get_children():
		child.queue_free()
	for child in get_children():
		if child is CollisionShape2D:
			child.queue_free()
	
	for island in islands:
		for i in range(island.size()):
			var p1 = island[i]
			var p2 = island[(i + 1) % island.size()]
			
			var segment = CollisionShape2D.new()
			segment.name = "Edge_" + str(i)
			var rect = RectangleShape2D.new()
			rect.size = Vector2(p1.distance_to(p2), EDGE_WIDTH)
			
			segment.shape = rect
			segment.position = (p1 + p2) / 2.0
			segment.rotation = (p2 - p1).angle()
			walls.add_child.call_deferred(segment)

	if get_node_or_null("Ground"):
		get_node("Ground").queue_free()
		
	var solid = get_node_or_null("Solid")
	if not solid:
		solid = CollisionPolygon2D.new()
		solid.name = "Solid"
		solid.build_mode = CollisionPolygon2D.BUILD_SOLIDS
		add_child(solid)
		solid.owner = self
	
	walls.collision_layer = 16 # Ship exterior layer
	walls.collision_mask = 0 #16 #ship exterior layer
	collision_layer = 1 # ship interior
	collision_mask = 257 # collide with other ships and enviroment
	# continuous_cd = RigidBody2D.CCD_MODE_CAST_RAY # causing an error with concave polys
	
	move_child.call_deferred(walls, -1)
	solid.polygon = islands[0] if islands.size() > 0 else PackedVector2Array()
	
	input_pickable = true
	if not input_event.is_connected(ground_input_event):
		input_event.connect(ground_input_event)

func _get_hex_poly() -> PackedVector2Array:
	var w_half = (HEX_WIDTH * 0.5) + 0.1
	var h_half = (HEX_HEIGHT * 0.5) + 0.1
	var h_quarter = (HEX_HEIGHT * 0.25) + 0.05
	
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
	var out: Array[PowerOutHex] = []
	for r in get_children():
		if r is Room:
			for h in r.get_out_hexes():
				if not h.is_powering:
					out.append(h)
	return out

func toggle_power(power_hex) -> void:
	if not my_character_inside():
		return
	
	if power_hex is PowerInHex:
		if power_hex.is_powered:
			remove_power_link_in(power_hex)
		else:
			set_next_avalible_power_out(power_hex)

func set_next_avalible_power_out(power_in : PowerInHex) -> bool:
	var power_outs = get_avalible_power_out()
	if power_outs.size() > 0:
		add_power_link(power_outs[0], power_in)
		return true
	return false

func add_power_link(power_out: PowerOutHex, power_in: PowerInHex) -> bool:
	if power_out.is_powering or power_in.is_powered: return false
	power_links[power_out] = power_in
	power_out.update_state()
	power_in.update_state()
	power_in.room.on_power_level_change.emit(power_in)
	return true

func remove_power_link_in(power_in : PowerInHex) -> bool:
	var power_out = power_links.find_key(power_in)
	if power_out:
		power_links.erase(power_out)
		power_out.update_state()
		power_in.update_state()
		power_in.room.on_power_level_change.emit(power_in)
		return true
	return false

func remove_power_link_out(power_out : PowerOutHex) -> bool:
	if power_out and power_links.has(power_out):
		var power_in = power_links[power_out]
		power_links.erase(power_out)
		power_out.update_state()
		power_in.update_state()
		power_in.room.on_power_level_change.emit(power_in)
		return true
	return false
#endregion

#region Health
func check_hud() -> void:
	max_hit_points = 0
	for child in get_children():
		if child is Room:
			max_hit_points += child.durability
	hit_points = max_hit_points
	hud = get_node_or_null("HUD")
	if not hud:
		hud = HUD_PREFAB.instantiate()
		add_child(hud)
	hud.initialize() # @ Kevin remove? could this be changed to ready?

func take_damage(amount : int) -> void:
	hit_points -= amount # property has callback that sets the hud to update

func death_check() -> void:
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
	ship_destroyed.emit()
	queue_free()

#endregion

#region InteriorExterior
func set_exterior_visible(_interactor : CharacterBody2D, entered : bool) -> void:
	if not my_character_inside() and _interactor != null:
		entered = false
	for r in get_children():
		if r is Room:
			r.roof.visible = not entered

#endregion

#region Pushing
func get_players_pushing() -> Array[PlayerCharacter]:
	var pushing_players : Array[PlayerCharacter] = []
	for p in get_players_from_manager():
		if p.pushing and p.ship == null and p.ground_body == self:
			pushing_players.append(p)
	return pushing_players

func apply_push_velocity(state : PhysicsDirectBodyState2D) -> void:
	var players = get_players_pushing()
	if players.is_empty():
		return
	
	for p in players:
		var target_vel = Vector2.ZERO if p.push_brake else state.linear_velocity + p.push_dir
		state.linear_velocity = lerp(state.linear_velocity, target_vel, p.thrust_accel * state.inverse_mass * 0.2 * state.step)

func apply_push_rotation(state : PhysicsDirectBodyState2D) -> void:
	var engines : Engines = get_engines()
	var players = get_players_pushing()
	var delta : float = state.step
	if players.is_empty():
		return
	
	var total_rot_input = 0.0
	var rot_input = _get_rotation_input()
	for p in players:
		total_rot_input += rot_input * p.rotate_speed
		
	var push_rot = (total_rot_input * state.inverse_mass) * 0.1
	if abs(push_rot) > 0.01:
		state.angular_velocity = lerp(state.angular_velocity, push_rot, 5.0 * delta)
	else:
		var drag = engines.drag_multiplier if engines else 2.0
		state.angular_velocity = lerp(state.angular_velocity, 0.0, drag * delta)

func find_nearest_ship() -> Ship:
	var out: Ship = null
	var min_dist = MAX_MERGE_DISTANCE
	
	for s in get_parent().get_children():
		if s is Ship and s != self:
			var d = to_global(center_of_mass).distance_to(s.to_global(s.center_of_mass))
			if d < min_dist:
				min_dist = d
				out = s
				
	return out

func generate_ghost_preview() -> void:
	ghost_preview = Node2D.new()
	ghost_preview.name = "GhostPreview"
	ghost_preview.z_index = 2
	get_parent().add_child(ghost_preview)
	
	for child in get_children():
		if child is Room:
			var room_dup = child.duplicate()
			ghost_preview.add_child(room_dup)
			room_dup.position = child.position
			room_dup.rotation = child.rotation
			
			for component in room_dup.get_children():
				if not component is Sprite2D:
					component.queue_free()

func clear_ghost_preview() -> void:
	if is_instance_valid(ghost_preview):
		ghost_preview.queue_free()
	merge_target_ship = null

func calculate_offset_transform(pushed_ship: Ship, target_cell: Vector2i, rot_idx_offset: int) -> Transform2D:
	var target_global_pos = grid_to_world(target_cell)
	var target_rot = (rot_idx_offset * (PI / 3.0)) + global_rotation
	
	var pushed_grid = pushed_ship.get_node_or_null("HexGrid")
	var origin_local = pushed_grid.map_to_local(Vector2i.ZERO) if pushed_grid else Vector2.ZERO
	var origin_global = pushed_ship.to_global(origin_local)
	
	return Transform2D(target_rot, target_global_pos) * Transform2D(pushed_ship.global_rotation, origin_global).inverse()

func calculate_snap_data(pushed_ship: Ship) -> Dictionary:
	var rot_idx_offset = int(round((pushed_ship.global_rotation - global_rotation) / (PI / 3.0)))
	var pushed_grid = pushed_ship.get_node_or_null("HexGrid")
	var origin_global = pushed_ship.to_global(pushed_grid.map_to_local(Vector2i.ZERO) if pushed_grid else Vector2.ZERO)
	
	var start_cell = world_to_grid(origin_global)
	var valid_placement = false
	var min_dist = INF
	var optimal_tf = calculate_offset_transform(pushed_ship, start_cell, rot_idx_offset)
	
	var queue = [start_cell]
	var distances = {start_cell: 0}
	
	while queue.size() > 0:
		var cell = queue.pop_front()
		var dist = distances[cell]
		var current_tf = calculate_offset_transform(pushed_ship, cell, rot_idx_offset)
		
		if is_transform_valid_for_merge(pushed_ship, current_tf, rot_idx_offset):
			var d_sq = grid_to_world(cell).distance_squared_to(origin_global)
			if d_sq < min_dist:
				min_dist = d_sq
				optimal_tf = current_tf
				valid_placement = true
		
		if dist < 6:
			for neighbor in neighborhood_coords(cell):
				if not distances.has(neighbor):
					distances[neighbor] = dist + 1
					queue.append(neighbor)
	
	return {
		"is_valid": valid_placement,
		"optimal_transform": optimal_tf,
		"rotation_index_offset": rot_idx_offset,
		"pushed_ship_transform": pushed_ship.global_transform
	}

func is_transform_valid_for_merge(pushed_ship: Ship, offset_tf: Transform2D, rot_idx_offset: int) -> bool:
	var projected_cells: Array[Vector2i] = []
	
	for room in pushed_ship.get_children():
		if room is Room:
			var target_cell = world_to_grid(offset_tf * room.global_position)
			var projected_rot = posmod(room.rot_index + rot_idx_offset, 6)
			projected_cells.append_array(get_cells_for_room(room, target_cell, projected_rot))
			
	return is_area_free(projected_cells) and is_adjacent_to_occupied(projected_cells)

func update_ghost_visuals(ghost_container: Node2D, snap_data: Dictionary) -> void:
	ghost_container.global_transform = snap_data.optimal_transform * snap_data.pushed_ship_transform
	ghost_container.modulate = Color(0, 1, 0, 0.5) if snap_data.is_valid else Color(1, 0, 0, 0.5)

func apply_merged_rooms(pushed_ship: Ship, snap_data: Dictionary) -> void:
	for room in pushed_ship.get_children():
		if room is Room:
			var dup_room = room.duplicate()
			add_child(dup_room)
			dup_room.global_transform = snap_data.optimal_transform * room.global_transform
			add_room(dup_room, world_to_grid(dup_room.global_position), posmod(room.rot_index + snap_data.rotation_index_offset, 6))
			
	refresh_ship_state()
	pushed_ship.queue_free()

func process_room_detachment(active_pushers: Array) -> bool:
	for pusher in active_pushers:
		if Input.is_action_just_pressed("detach"):
			var target_cell = world_to_grid(pusher.global_position + (pusher.push_dir * 45.0))
			var target_room = occupied_cells.get(target_cell)
			
			if target_room and get_total_room_count() > 1:
				detach_room_to_new_ship(target_room, pusher.push_dir)
				return true
	return false

func get_total_room_count() -> int:
	var count = 0
	for child in get_children():
		if child is Room:
			count += 1
	return count

func _setup_new_ship(new_ship: Ship, rooms: Array, velocity_offset: Vector2 = Vector2.ZERO, position_offset: Vector2 = Vector2.ZERO) -> void:
	get_parent().add_child(new_ship)
	new_ship.global_transform = global_transform
	new_ship.global_position += position_offset
	new_ship.linear_velocity = linear_velocity + velocity_offset
	new_ship.angular_velocity = angular_velocity
	
	for room in rooms:
		var pos = room.grid_pos
		var rot = room.rot_index
		remove_room(room)
		new_ship.add_room(room, pos, rot)
		
	new_ship.refresh_ship_state()

func detach_room_to_new_ship(target_room: Room, push_dir: Vector2) -> void:
	var detached_ship = SHIP_PREFAB.instantiate()
	_setup_new_ship(detached_ship, [target_room], push_dir * 350.0, push_dir * 25.0)
	
	refresh_ship_state()

#endregion

#region islands
func separate_islands() -> void:
	var rooms = []
	for child in get_children():
		if child is Room:
			rooms.append(child)
	
	if rooms.is_empty():
		return
	
	var processed_rooms = []
	var islands = []

	for room in rooms:
		if room in processed_rooms:
			continue
			
		var current_group = []
		var queue = [room]
		processed_rooms.append(room)
		
		while queue.size() > 0:
			var current = queue.pop_front()
			current_group.append(current)
			
			for neighbor in find_neighbors(current):
				if neighbor not in processed_rooms:
					processed_rooms.append(neighbor)
					queue.append(neighbor)
		
		islands.append(current_group)

	if islands.size() > 1:
		for i in range(1, islands.size()):
			_spawn_island_ship(islands[i])
		refresh_ship_state()

func _spawn_island_ship(island_rooms: Array) -> void:
	var new_ship = SHIP_PREFAB.instantiate()
	_setup_new_ship(new_ship, island_rooms)

#endregion
