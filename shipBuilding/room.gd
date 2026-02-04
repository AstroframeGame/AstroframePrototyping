class_name Room
extends Node2D
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
	#set_shape() # needs to be called or else collider won't work
	#create_colliders()
	pass

func create_colliders():
	var poly = _get_hex_poly()
	for i in range(6):
		var to_i = i % 6
		var wall : CollisionShape2D = CollisionShape2D.new()
		var seg = SegmentShape2D.new()
		seg.a = poly[i]
		seg.b = poly[to_i]
		wall.debug_color = Color(0.847, 0.0, 0.451, 0.42)
		wall.shape = seg
		add_sibling.call_deferred(wall)

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
