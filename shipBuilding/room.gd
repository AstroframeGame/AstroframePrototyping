class_name Room
extends Node2D

@warning_ignore("unused_signal") # used in ship
signal on_power_level_change(room : Room)

@export var durability = 10
@export var original_color : Color


var blink_sfx_timer : Timer

func _ready() -> void:

	original_color = modulate
	blink_sfx_timer = Timer.new()
	blink_sfx_timer.wait_time = 0.4
	blink_sfx_timer.one_shot = true
	add_child(blink_sfx_timer)

#region Getters
var ship : Ship:
	get:
		return get_parent() as Ship

var rot_index : int:
	get:
		return int(round(rotation / (PI / 3.0)))
var grid_pos : Vector2i:
	get:
		if ship:
			return ship.world_to_grid(global_position)
		print_debug(name, " has no ship")
		return global_position
#endregion

#region Power
var power_level : int:
	get:
		var in_hexes = 0
		for h in get_in_hexes():
			if h.is_powered:
				in_hexes += 1
		return in_hexes

func get_in_hexes() -> Array[PowerInHex]:
	var hexes : Array[PowerInHex] = []
	for h in get_children():
		if h is PowerInHex:
			hexes.append(h)
	return hexes

func get_out_hexes() -> Array[PowerOutHex]:
	var hexes : Array[PowerOutHex] = []
	for h in get_children():
		if h is PowerOutHex:
			hexes.append(h)
	return hexes
#endregion

#region VFX
func blink_red():
	if blink_sfx_timer.time_left>0:
		return
	blink_sfx_timer.start()
	modulate = Color.PALE_VIOLET_RED
	await blink_sfx_timer.timeout
	modulate = original_color
	blink_sfx_timer.start()
#endregion

#region Walls
func get_walls() -> Array[Wall]:
	var walls: Array[Wall] = []
	for child in get_children():
		if child is Wall:
			walls.append(child)
	return walls
#endregion
