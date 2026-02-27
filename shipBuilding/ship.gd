class_name Ship
extends RigidBody2D

signal room_clicked(room: Room, button_index: int)
signal on_airlock_interaction(interactor : PlayerCharacter, is_inside : bool) # called from airlock
signal ship_destroyed
signal on_hit()

const FLIGHT_DEADZONE = 0.05 #screen %
const HEX_WIDTH = 78
const HEX_HEIGHT = 90

const HEX_GRID_PREFAB = preload("res://shipBuilding/prefabs/hex_grid.tscn")
const HUD = preload("res://shipAI/prefabs/hud.tscn")
const SHIP_PREFAB = preload("res://shipBuilding/prefabs/ship.tscn")
const MAX_MERGE_DISTANCE: float = 600.0

const SPARKS_PREFAB = preload("res://art/vfx/sparks.tscn")
const SPARKS_SPEED_THRESH = 10
const EXPLOSION_PREFAB = preload("res://art/vfx/explosion.tscn")
const HIT_SHIP_VFX_PREFAB = preload("res://art/vfx/hit_ship_vfx.tscn")

## Multiplayer Start

@onready var multiplayer_manager: MultiplayerManager = get_tree().root.get_node("Hub/MultiplayerManager")
var players: Array[PlayerCharacter]
var driver: PlayerCharacter
@onready var target_linear_velocity: Vector2 = Vector2.ZERO
@onready var target_angular_velocity: float = 0.0
@onready var target_transform: Transform2D = global_transform

## Multiplayer End

var grid: TileMapLayer:
	get:
		return get_node("HexGrid")
@export var hud : ShipHud = null

var merge_target_ship: Ship = null
var ghost_preview: Node2D = null
var occupied_cells: Dictionary[Vector2i, Room] = {} # only calculated in ship_building
@export var power_links : Dictionary[PowerOutHex, PowerInHex]

@export var max_hit_points : int = 0
@export var _hit_points : int = 0
var hit_points : int:
	get:
		return _hit_points
	set(value):
		if value < _hit_points:
			on_hit.emit()
		_hit_points = value


func _ready() -> void:
	initialize_ship()
	
	on_airlock_interaction.connect(set_exterior_visible)
	on_hit.connect(hud.update_hp_bar)
	on_hit.connect(death_check)
	
	# for sparks
	contact_monitor = true
	max_contacts_reported = 5
	
	z_index = 1

func ground_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		var cell = world_to_grid(get_global_mouse_position())
		if occupied_cells.has(cell):
			var room = occupied_cells[cell]
			#print("Room ", room, " was clicked")
			room_clicked.emit(room, event.button_index)

#region Piloting
func initialize_ship():
	update_occupied_cells()
	update_colliders()
	separate_islands()
	calc_center_of_mass()
	check_hud()
	

func get_engines() -> Engines:
	for r in get_children():
		if r is Engines:
			return r
	return null
func get_piloting() -> Piloting:
	for r in get_children():
		if r is Piloting:
			if r.is_active():
				return r
	return null
func get_cannons() -> Array[Cannon]:
	var cannons : Array[Cannon]
	for r in get_children():
		if r is Cannon:
			cannons.append(r)
	return cannons
func get_players_from_manager() -> Array[PlayerCharacter]:
	if multiplayer_manager:
		return multiplayer_manager.players
	return []

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if is_multiplayer_authority():
		var engines :Engines = get_engines()
		var piloting : Piloting = get_piloting()
		var pushing : bool = get_players_pushing().size() > 0
		var delta = state.step
		
		if engines and piloting:
			state.angular_velocity = piloting.get_goal_angular_velocity()
			var goal_vel: Vector2 = piloting.get_goal_velocity(state.linear_velocity)
			if not piloting.is_idling():
				state.linear_velocity = lerp(state.linear_velocity, goal_vel, engines.get_thrust() * state.inverse_mass * delta)
		elif pushing:
			apply_push_rotation(state)
			apply_push_velocity(state)
		elif engines: # autodrag
			state.angular_velocity = lerp(state.angular_velocity, 0.0, state.inverse_mass * engines.drag_multiplier * delta)
			state.linear_velocity = lerp(state.linear_velocity, Vector2.ZERO, engines.get_thrust() * state.inverse_mass * engines.drag_multiplier * delta)
		
	eval_sparks(state)

#region ClientInterpolation
func _physics_process(delta: float) -> void:
	if is_multiplayer_authority():
		return
	
	global_transform = global_transform.interpolate_with(target_transform, 10.0 * delta)
	linear_velocity = linear_velocity.lerp(target_linear_velocity, 10.0 * delta)
	angular_velocity = lerp(angular_velocity, target_angular_velocity, 10.0 * delta)
#endregion

@rpc("authority", "call_remote", "unreliable")
func sync_state(gt: Transform2D, lv: Vector2, av: float):
	if is_multiplayer_authority():
		return
	
	target_transform        = gt
	target_linear_velocity  = lv
	target_angular_velocity = av

func calc_center_of_mass():
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
	occupied_cells.clear()
	for room in get_children():
		if room is Room:
			add_room(room, room.grid_pos, room.rot_index)
			#var cells = get_cells_for_room(room, room.grid_pos, room.rot_index)
			#for c in cells:
				#occupied_cells[c] = room

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
			if not target_cell in cells:
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
				continue
			var _room = occupied_cells[coord]
			if not _room in neighbors:
				neighbors.append(_room)
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
			var neighbor = grid.get_neighbor_cell(cell, side)
			if occupied_cells.has(neighbor):
				return true
	return false
#endregion

#region Add and Remove Room

func add_room(room: Room, cell: Vector2i, rot_index: int) -> void:
	room.position = to_local(grid_to_world(cell))
	room.rotation = rot_index * PI / 3.0
	
	if room.get_parent() != self:
		add_child(room)
	
	var cells = get_cells_for_room(room, cell, rot_index)
	for c in cells:
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
	# remove power links
	for hex in room.get_in_hexes():
		if hex in power_links.values():
			remove_power_link_in(hex)
		hex.update_state()
	for hex in room.get_out_hexes():
		if hex in power_links.keys():
			remove_power_link_out(hex)
		hex.update_state()
	
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
	
	var old_edge = get_node_or_null("Edge")
	if old_edge:
		old_edge.queue_free()
	for child in get_children():
		if child is CollisionShape2D:
			child.queue_free()
	
	
	var walls : StaticBody2D = get_node_or_null("Walls")
	if not walls:
		walls = StaticBody2D.new()
		walls.name = "Walls"
		add_child(walls)
	
	for child in walls.get_children():
		if child is CollisionShape2D:
			child.queue_free()
	
	var wall_thickness = 8.0
	
	for island in islands:
		for i in range(island.size()):
			var p1 = island[i]
			var p2 = island[(i + 1) % island.size()]
			
			var segment = CollisionShape2D.new()
			segment.name = "Edge_" + str(i)
			
			var rect = RectangleShape2D.new()
			var length = p1.distance_to(p2)
			
			rect.size = Vector2(length, wall_thickness)
			segment.shape = rect
			
			segment.position = (p1 + p2) / 2.0
			segment.rotation = (p2 - p1).angle()
			
			walls.add_child.call_deferred(segment)

	var area : Area2D = get_node_or_null("Ground")
	if area:
		area.queue_free()
		
	
	var solid = get_node_or_null("Solid")
	if not solid:
		solid = CollisionPolygon2D.new()
		solid.name = "Solid"
		solid.build_mode = CollisionPolygon2D.BUILD_SOLIDS
		add_child(solid)
		solid.owner = self
		print("Fallback: ", name, " creating solid")
	
	
	walls.collision_layer = 16 # Ship exterior layer
	walls.collision_mask = 0#16 #ship exterior layer
	collision_layer = 1 # ship interior
	collision_mask = 257 # collide with other ships and enviroment
	continuous_cd = RigidBody2D.CCD_MODE_CAST_RAY
	
	move_child.call_deferred(walls, -1)
	
	if islands.size() > 0:
		solid.polygon = islands[0]
	else:
		solid.polygon = PackedVector2Array()
	
	
	input_pickable = true
	if not input_event.is_connected(ground_input_event):
		input_event.connect(ground_input_event)


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
	if not my_character_inside():
		return
	#if power_hex is PowerOutHex && power_hex.is_powering:
		## turn off power
		#remove_power_link_out(power_hex)
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
	power_out.update_state()
	power_in.update_state()
	power_in.room.on_power_level_change.emit(power_in)
	return true

func remove_power_link_in(power_in : PowerInHex):
	var power_out = power_links.find_key(power_in)
	if power_out != null:
		power_links.erase(power_out)
		power_out.update_state()
		power_in.update_state()
		power_in.room.on_power_level_change.emit(power_in)
		return true
	return false

func remove_power_link_out(power_out : PowerOutHex):
	if power_out != null && power_links.has(power_out):
		var power_in = power_links[power_out]
		power_links.erase(power_out)
		power_out.update_state()
		power_in.update_state()
		power_in.room.on_power_level_change.emit(power_in)
		return true
	return false
#endregion

#region Health
func check_hud():
	for child in get_children():
		if child is Room:
			max_hit_points += child.durability
	hit_points = max_hit_points
	hud = get_node_or_null("HUD")
	if not hud:
		hud = HUD.instantiate()
		add_child(hud)
	hud.initialize() # @ Kevin remove?

func take_damage(amount:int, pos_ws : Vector2):
	hit_points -= amount # property has callback that sets the hud to update
	hit_vfx(pos_ws)

func death_check():
	if hit_points > 0:
		return 
	death_explosion()
	
func death_explosion():
	var rooms: Array[Room] = []
	for child in get_children():
		if child is Room:
			rooms.append(child)
	
	for room in rooms:
		var push_dir = (room.global_position - to_global(center_of_mass)).normalized()
		
		var debris_ship: Ship = SHIP_PREFAB.instantiate()
		get_parent().add_child(debris_ship)
		
		# Match current state
		debris_ship.global_transform = global_transform
		debris_ship.linear_velocity = linear_velocity
		debris_ship.angular_velocity = angular_velocity + randf_range(-2.0, 2.0)
		
		var grid_pos = room.grid_pos
		var rot_index = room.rot_index
		var pos = room.global_position
		remove_room(room)
		debris_ship.add_room.call_deferred(room, grid_pos, rot_index)
		
		var explosion_impulse = randf_range(20.0, 100.0)
		debris_ship.apply_central_impulse(push_dir * explosion_impulse)
		
		debris_ship.initialize_ship()
		explosion(pos)

	ship_destroyed.emit()
	queue_free()
#endregion

#region InteriorExterior

func my_character_inside() -> bool:
	if multiplayer_manager and multiplayer_manager.my_player:
		return multiplayer_manager.my_player.ship == self
	return false

# interactor will be null if the editor calls this 
func set_exterior_visible(_interactor : CharacterBody2D, entered : bool):
	if not my_character_inside() and _interactor != null:
		entered = false
	if _interactor.is_local_player:
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
		if p.push_brake:
			state.linear_velocity = lerp(state.linear_velocity, Vector2.ZERO, p.thrust_accel * state.inverse_mass * 0.2 * state.step)
		else:
			state.linear_velocity = lerp(state.linear_velocity, state.linear_velocity + p.push_dir, p.thrust_accel * state.inverse_mass * 0.2 * state.step)

func apply_push_rotation(state : PhysicsDirectBodyState2D) -> void:
	var delta = state.step
	var push_rot = 0.0
	var players = get_players_pushing()
	if players.is_empty():
		return
	var total_rot_input = 0.0
	for p in players:
		var look_dir = InputHelper.mouse_center_offset_deadzone(FLIGHT_DEADZONE)
		var rot_amount = look_dir.x * 0.01
		if not InputHelper.using_mouse:
			rot_amount = InputHelper.controller_look.x
		total_rot_input += rot_amount * p.rotate_speed
	push_rot = (total_rot_input * state.inverse_mass) * 0.1
	if abs(push_rot) > 0.01:
		state.angular_velocity = lerp(state.angular_velocity, push_rot, 5.0 * delta)
#endregion

#region merging

func _process(_delta: float) -> void:
	# if not multiplayer auth: @Tapesh
	#   clear_ghost_preview()
	#   return
	
	if is_multiplayer_authority():
		sync_state.rpc(global_transform, linear_velocity, angular_velocity)
		
	var pushers = get_players_pushing()
	
	if pushers.is_empty():
		clear_ghost_preview()
		return
		
	if process_room_detachment(pushers):
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
	
	for child_node in get_children():
		if child_node is Room:
			var room_duplicate = child_node.duplicate()
			ghost_preview.add_child(room_duplicate)
			room_duplicate.position = child_node.position
			room_duplicate.rotation = child_node.rotation
			
			for room_component in room_duplicate.get_children():
				if not room_component is Sprite2D:
					room_component.queue_free()

func clear_ghost_preview() -> void:
	if is_instance_valid(ghost_preview):
		ghost_preview.queue_free()
	merge_target_ship = null

func calculate_offset_transform(pushed_ship: Ship, target_grid_cell: Vector2i, rotation_index_offset: int) -> Transform2D:
	var target_global_position = grid_to_world(target_grid_cell)
	var target_rotation = (rotation_index_offset * (PI / 3.0)) + global_rotation
	
	var pushed_grid = pushed_ship.get_node_or_null("HexGrid")
	var pushed_origin_local = pushed_grid.map_to_local(Vector2i.ZERO) if pushed_grid else Vector2.ZERO
	var pushed_origin_global = pushed_ship.to_global(pushed_origin_local)
	
	var origin_transform = Transform2D(pushed_ship.global_rotation, pushed_origin_global)
	var destination_transform = Transform2D(target_rotation, target_global_position)
	
	return destination_transform * origin_transform.inverse()

func calculate_snap_data(pushed_ship: Ship) -> Dictionary:
	var relative_angle = pushed_ship.global_rotation - global_rotation
	var rotation_index_offset = int(round(relative_angle / (PI / 3.0)))
	
	var pushed_grid = pushed_ship.get_node_or_null("HexGrid")
	var pushed_origin_local = pushed_grid.map_to_local(Vector2i.ZERO) if pushed_grid else Vector2.ZERO
	var pushed_origin_global = pushed_ship.to_global(pushed_origin_local)
	
	var starting_cell = world_to_grid(pushed_origin_global)
	var _closest_valid_cell = starting_cell
	var is_placement_valid = false
	var minimum_distance = INF
	
	var cells_to_visit = [starting_cell]
	var cell_distances = {starting_cell: 0}
	var optimal_transform = calculate_offset_transform(pushed_ship, starting_cell, rotation_index_offset)
	
	while cells_to_visit.size() > 0:
		var current_cell = cells_to_visit.pop_front()
		var current_distance_steps = cell_distances[current_cell]
		var current_transform = calculate_offset_transform(pushed_ship, current_cell, rotation_index_offset)
		
		if is_transform_valid_for_merge(pushed_ship, current_transform, rotation_index_offset):
			var cell_global_position = grid_to_world(current_cell)
			var spatial_distance = cell_global_position.distance_squared_to(pushed_origin_global)
			
			if spatial_distance < minimum_distance:
				minimum_distance = spatial_distance
				_closest_valid_cell = current_cell
				optimal_transform = current_transform
				is_placement_valid = true
		
		if current_distance_steps < 6:
			for neighbor_cell in neighborhood_coords(current_cell):
				if not cell_distances.has(neighbor_cell):
					cell_distances[neighbor_cell] = current_distance_steps + 1
					cells_to_visit.append(neighbor_cell)
	
	return {
		"is_valid": is_placement_valid,
		"optimal_transform": optimal_transform,
		"rotation_index_offset": rotation_index_offset,
		"pushed_ship_transform": pushed_ship.global_transform
	}

func is_transform_valid_for_merge(pushed_ship: Ship, offset_transform: Transform2D, rotation_index_offset: int) -> bool:
	var projected_occupied_cells: Array[Vector2i] = []
	
	for room_node in pushed_ship.get_children():
		if room_node is Room:
			var projected_global_position = offset_transform * room_node.global_position
			var target_room_cell = world_to_grid(projected_global_position)
			var projected_rotation_index = posmod(room_node.rot_index + rotation_index_offset, 6)
			
			var room_required_cells = get_cells_for_room(room_node, target_room_cell, projected_rotation_index)
			projected_occupied_cells.append_array(room_required_cells)
			
	return is_area_free(projected_occupied_cells) and is_adjacent_to_occupied(projected_occupied_cells)

func update_ghost_visuals(ghost_container: Node2D, snap_data: Dictionary) -> void:
	ghost_container.global_transform = snap_data.optimal_transform * snap_data.pushed_ship_transform
	ghost_container.modulate = Color(0, 1, 0, 0.5) if snap_data.is_valid else Color(1, 0, 0, 0.5)

func apply_merged_rooms(pushed_ship: Ship, snap_data: Dictionary) -> void:
	for room_node in pushed_ship.get_children():
		if room_node is Room:
			var duplicate_room = room_node.duplicate()
			add_child(duplicate_room)
			
			duplicate_room.global_transform = snap_data.optimal_transform * room_node.global_transform
			
			var merged_cell = world_to_grid(duplicate_room.global_position)
			var merged_rotation_index = posmod(room_node.rot_index + snap_data.rotation_index_offset, 6)
			
			add_room(duplicate_room, merged_cell, merged_rotation_index)
			
	initialize_ship()
	pushed_ship.queue_free()
#endregion

#region detaching
func process_room_detachment(active_pushers: Array) -> bool:
	for pusher in active_pushers:
		if Input.is_action_just_pressed("detach"):
			var projection_distance = 45.0
			var contact_global_position = pusher.global_position + (pusher.push_dir * projection_distance)
			var targeted_grid_cell = world_to_grid(contact_global_position)
			var targeted_room_node = occupied_cells.get(targeted_grid_cell)
			
			if targeted_room_node and get_total_room_count() > 1:
				detach_room_to_new_ship(targeted_room_node, pusher.push_dir)
				return true
	return false

func get_total_room_count() -> int:
	var total_rooms = 0
	for child_node in get_children():
		if child_node is Room:
			total_rooms += 1
	return total_rooms

func detach_room_to_new_ship(target_room: Room, push_direction: Vector2) -> void:
	var detached_ship_instance : Ship = SHIP_PREFAB.instantiate()
	get_parent().add_child(detached_ship_instance)
	
	var separation_offset = push_direction * 25.0
	var separation_velocity = push_direction * 350.0
	
	detached_ship_instance.global_transform = global_transform
	detached_ship_instance.global_position += separation_offset
	detached_ship_instance.linear_velocity = linear_velocity + separation_velocity
	detached_ship_instance.angular_velocity = angular_velocity
	
	var original_grid_pos = target_room.grid_pos
	var original_rot_index = target_room.rot_index
	remove_room(target_room)
	detached_ship_instance.add_room(target_room, original_grid_pos, original_rot_index)
	
	separate_islands()
	
	initialize_ship()
	detached_ship_instance.initialize_ship()
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
		print_debug("Warning, Separating islands on ship")
		for i in range(1, islands.size()):
			_spawn_island_ship(islands[i])
		initialize_ship()

func _spawn_island_ship(island_rooms: Array) -> void:
	var new_ship :Ship = SHIP_PREFAB.instantiate()
	get_parent().add_child(new_ship)
	
	new_ship.global_transform = global_transform
	new_ship.linear_velocity = linear_velocity
	new_ship.angular_velocity = angular_velocity
	
	for room in island_rooms:
		var pos = room.grid_pos
		var rot = room.rot_index
		remove_room(room)
		new_ship.add_room(room, pos, rot)
		
	new_ship.initialize_ship()
#endregion

#region vfx
func eval_sparks(state : PhysicsDirectBodyState2D):
	if not get_tree().get_frame() % 10 == 0:
		return
	for i in state.get_contact_count():
		var pos = state.get_contact_collider_position(i)
		var rot = state.get_contact_local_normal(i).angle()
		var speed = state.get_velocity_at_local_position(to_local(pos)).length()
		print(speed)
		if speed > SPARKS_SPEED_THRESH:
			var sparks : Node2D= SPARKS_PREFAB.instantiate()
			sparks.global_position = pos
			sparks.global_rotation = rot
			sparks.restart()
			ProjectileManager.add_child(sparks)

func explosion(pos : Vector2):
	var g = EXPLOSION_PREFAB.instantiate()
	g.global_position = pos
	for c in g.get_children():
		if c is GPUParticles2D:
			c.restart()
	ProjectileManager.add_child(g)

func hit_vfx(pos : Vector2):
	var g = HIT_SHIP_VFX_PREFAB.instantiate()
	g.global_position = pos
	for c in g.get_children():
		if c is GPUParticles2D:
			c.restart()
	ProjectileManager.add_child(g)
#endregion
