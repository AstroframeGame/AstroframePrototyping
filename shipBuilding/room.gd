class_name Room
extends CollisionPolygon2D
# a collision polygon will need a body as the parent. all rooms must be parented to the Ship (body)

var ship : Ship:
	get:
		return get_parent() as Ship

var rot_index : int:
	get:
		return int(round(rotation / (PI / 3.0)))
		
var grid_pos : Vector2i:
	get:
		return ship.world_to_grid(global_position)

# not sure how durability is going to work, but probably once a room takes enough damage, it becomes
# inoperable or breaks
@export var durability = 40

# feels like a bad place for the global info which is also stored in the HexGrid tilemap layer
const HEX_WIDTH = 78 #164.0
const HEX_HEIGHT = 90 #190.0

# this method is not necessary, but is a callback from when building with a callback
# to the grid that is on the hex editor. feel free to remove.
func initialize(_grid: TileMapLayer) -> void:
	print(ship.find_neightbors(self))
	
func _ready() -> void:
	set_shape() # needs to be called or else collider won't work

# this calculates the polygon of the room for collisions and clicking
func set_shape():
	var polys: Array[PackedVector2Array] = []
	var base_hex = _get_hex_poly()
	
	for child in get_children():
		if not child is Sprite2D: continue
		var poly = base_hex.duplicate()
		for i in range(poly.size()):
			poly[i] += child.position
		polys.append(poly)

	var islands: Array[PackedVector2Array] = []
	for p in polys:
		var i = islands.size() - 1
		while i >= 0:
			var result = Geometry2D.merge_polygons(islands[i], p)
			if result.size() == 1:
				p = result[0]
				islands.remove_at(i)
			i -= 1
		islands.append(p)
	if not islands.is_empty():
		polygon = islands[0]

# this calculates the mathmatical polygon based off the Hex width and height set here.
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
