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

const SPARKS_PREFAB = preload("res://art/vfx/sparks.tscn")
const SPARKS_SPEED_THRESH = 10
const EXPLOSION_PREFAB = preload("res://art/vfx/explosion.tscn")
const HIT_SHIP_VFX_PREFAB = preload("res://art/vfx/hit_ship_vfx.tscn")
const EXPLOSION_SFX_PREFAB = preload("res://audio/sfx_prefabs/explosion_sfx.tscn")
const SFX_EXPLOSION = preload("res://audio/sfx/explosion.wav")
const SFX_HULL_DESTROY = preload("res://audio/sfx/hull_destroy.wav")

var _is_dead: bool = false

var grid: TileMapLayer:
	get:
		return get_node("HexGrid")
@export var hud : ShipHud = null


var occupied_cells: Dictionary[Vector2i, Room] = {} # only calculated in ship_building
@export var power_links : Dictionary[PowerOutHex, PowerInHex]

@export var drag_multiplier = 0.01
@export var max_hit_points : int = 0
@export var _hit_points : int = 0
var hit_points : int:
	get:
		return _hit_points
	set(value):
		if value < _hit_points:
			on_hit.emit()
		_hit_points = value

enum SHIP_MODE {EDITING, COMBAT}
@onready var ship_mode : SHIP_MODE = SHIP_MODE.COMBAT

func _ready() -> void:
	center_rooms();
	initialize_ship()
	
	on_airlock_interaction.connect(set_exterior_visible)
	on_hit.connect(hud.update_hp_bar)
	on_hit.connect(death_check)
	
	# for sparks
	contact_monitor = true
	max_contacts_reported = 5
	
	z_index = 1
	
	

func center_rooms():
	var middlevec = Vector2(0,0);
	var num = 0;
	for n in get_children():
		if n is Room:
			middlevec += n.position;
			num += 1;
	middlevec /= num;
	for n in get_children():
		if n is Room:
			n.position -= middlevec;

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
func has_engines() -> bool:
	return get_engines() != null
func get_boost_thrust() -> float:
	var o = 0
	for r in get_children():
		if r is Engines:
			o += r.get_boost_thrust()
	return o
func get_thrust() -> float:
	var o = 0
	for r in get_children():
		if r is Engines:
			o += r.get_thrust()
	return o

func get_piloting() -> Piloting:
	for r in get_children():
		if r is Piloting:
			if r.is_active():
				return r
	return null
func get_auto_piloting()->Autopilot:
	for r in get_children():
		if r is Autopilot:
			if r.is_active():
				return r
	return null
func get_cannons() -> Array[Cannon]:
	var cannons : Array[Cannon]
	for r in get_children():
		if r is Cannon:
			cannons.append(r)
	return cannons
func get_shields()->Array[Shields_Room]:
	var shields_rooms : Array[Shields_Room]
	for r in get_children():
		if r is Shields_Room:
			shields_rooms.append(r)
	return shields_rooms
func get_active_shields()->Array[Shield]:
	var shields : Array[Shield]
	for s in get_shields():
		if s.shield != null and s.shield.visible:
			shields.append(s.shield)
	return shields
func get_swivel_guns()->Array[SwivelCannon]:
	var swivels : Array[SwivelCannon]
	for s in get_children():
		if s is SwivelCannon:
			swivels.append(s)
	return swivels
func get_players_from_manager() -> Array[PlayerCharacter]:
	var multiplayer_manager :MultiplayerManager= get_tree().root.get_node("Hub/MultiplayerManager")
	if multiplayer_manager:
		return multiplayer_manager.players
	return []

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	var piloting : Piloting = get_piloting()
	var autopilot : Autopilot = get_auto_piloting()

	var delta = state.step
	
	if has_engines() and piloting:
		state.linear_velocity = piloting.get_velocity(state)
	elif has_engines() and autopilot:
		print(state.angular_velocity)
	elif has_engines(): # autodrag
		state.angular_velocity = lerp(state.angular_velocity, 0.0, state.inverse_mass * drag_multiplier * delta)
		state.linear_velocity = lerp(state.linear_velocity, Vector2.ZERO, get_thrust() * state.inverse_mass * drag_multiplier * delta)
		#pass
	eval_sparks(state)

func calc_center_of_mass():
	var hex_mass = 2.0
	var total_mass = 0.0
	var weighted_pos_sum = Vector2.ZERO
	
	for child in get_children():
		if child is Room:
			for hex in child.get_children():
				if hex is Hex:
					total_mass += hex_mass
					weighted_pos_sum += (child.transform * hex.position) * hex_mass
					
	if total_mass == 0:
		return
		
	mass = total_mass
	center_of_mass_mode = RigidBody2D.CENTER_OF_MASS_MODE_CUSTOM
	center_of_mass = weighted_pos_sum / total_mass

## return ship's center of mass as a global position
func get_center()->Vector2:
	return to_global(center_of_mass)

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
		if child is Hex:
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
				if room_child is Hex:
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
	
	var points = [];
	var indices = [];
	var num = 0;
	for island in islands:
		for i in range(island.size()):
			var p1 = island[i]
			var p2 = island[(i + 1) % island.size()]
			
			points.append(p2);
			
			indices.append(num);
			num += 1;
			var segment = CollisionShape2D.new()
			segment.name = "Edge_" + str(i)
			
			var rect = RectangleShape2D.new()
			var length = p1.distance_to(p2)
			
			rect.size = Vector2(length, wall_thickness)
			segment.shape = rect
			
			segment.position = (p1 + p2) / 2.0
			segment.rotation = (p2 - p1).angle()
			
			walls.add_child.call_deferred(segment)
	var new_navigation_mesh = NavigationPolygon.new()
	new_navigation_mesh.add_outline(points)
	NavigationServer2D.bake_from_source_geometry_data(new_navigation_mesh, NavigationMeshSourceGeometryData2D.new());
	
	if has_node("NavigationRegion2D"):
		$NavigationRegion2D.navigation_polygon = new_navigation_mesh
	
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
		#print("Fallback: ", name, " creating solid")
	
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

func get_available_power_in() -> Array[PowerInHex]:
	var _in: Array[PowerInHex] = []
	for r in get_children():
		if r is Room:
			for h in r.get_in_hexes():
				if not h.is_powered:
					_in.append(h)
	return _in

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
	if power_in.room:
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
		if power_in:
			power_in.update_state()
			power_in.room.on_power_level_change.emit(power_in)
		return true
	return false
	
func pair_all_links():
	power_links.clear()
	
	var power_in = get_available_power_in()
	for h : PowerInHex in power_in:
		await get_tree().process_frame
		set_next_avalible_power_out(h)
#endregion

#region Health
func check_hud():
	max_hit_points = 0
	for child in get_children():
		if child is Room:
			max_hit_points += child.durability
	hit_points = max_hit_points
	hud = get_node_or_null("HUD")
	if not hud:
		hud = HUD.instantiate()
		add_child(hud)
	hud.initialize()

func take_damage(amount:int, pos_ws : Vector2):
	hit_points -= amount # property has callback that sets the hud to update
	if get_active_shields().is_empty():
		for shield in get_shields():
			shield.blink_red()
	hit_vfx(pos_ws)

func death_check():
	if hit_points > 0 or _is_dead:
		return 
		
	for pc in get_tree().get_nodes_in_group("player_controller"):
		if pc.ship == self:
			pc.update_layers(false)
	_is_dead = true
	call_deferred("death_explosion")
	
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
		debris_ship.add_room(room, grid_pos, rot_index)
		
		var explosion_impulse = randf_range(20.0, 100.0)
		debris_ship.apply_central_impulse(push_dir * explosion_impulse)
		
		debris_ship.initialize_ship()
		explosion(pos)
	
	var explosion_sfx : AudioStreamPlayer2D = EXPLOSION_SFX_PREFAB.instantiate()
	explosion_sfx.play_quantity(SFX_EXPLOSION, len(rooms))
	explosion_sfx.global_position = global_position
	ProjectileManager.add_child(explosion_sfx)
	
	ship_destroyed.emit()
	queue_free()
#endregion

#region InteriorExterior

func my_character_inside() -> bool:
	var multiplayer_manager = get_tree().root.find_child("MultiplayerManager", true, false)
	if multiplayer_manager and multiplayer_manager.my_player:
		return multiplayer_manager.my_player.ship == self
	return false

# interactor will be null if the editor calls this 
func set_exterior_visible(_interactor : CharacterBody2D, entered : bool):
	if not my_character_inside() and _interactor != null:
		entered = false
	for r in get_children():
		if r is Room:
			pass
#endregion


func get_total_room_count() -> int:
	var total_rooms = 0
	for child_node in get_children():
		if child_node is Room:
			total_rooms += 1
	return total_rooms


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
	
	var hit_sfx : AudioStreamPlayer2D = EXPLOSION_SFX_PREFAB.instantiate()
	hit_sfx.play_quantity(SFX_HULL_DESTROY, 1)
	hit_sfx.global_position = pos
	ProjectileManager.add_child(hit_sfx)
#endregion
