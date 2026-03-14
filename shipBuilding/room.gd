class_name Room
extends Node2D

@warning_ignore("unused_signal") # used in ship
signal on_power_level_change(room : Room)

@export var durability = 10
@export var original_color : Color
@onready var roof: Node2D = $Roof

var blink_sfx_timer : Timer

func _ready() -> void:
	roof.z_index = 10
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

#region Upgrading / Augmentation
@export var augments : Array[Augment]
## return index of augment in Augments Array
func augment_in_list(type:Variant)->int:
	for augment in augments:
		# needs better solution but how many times is someone
		# going to keep the base but repeatedly redo/undo
		# an augment ¯\_(ツ)_/¯
		if augment == null:
			continue
		if is_instance_of(augment, type):
			return augments.find(augment)
	return -1

func at_augment_limit(type:Variant, limit:int)->bool:
	var count = 0
	for augment in augments:
		if augment == null:
			continue
		if is_instance_of(augment, type):
			count += 1
	return count == limit

func pair_augments(augment_type:Variant)->void:
	ship.update_occupied_cells()
	for neighbor in ship.find_neighbors(self):
		if is_instance_of(neighbor, augment_type):
			if not neighbor.at_augment_limit(augment_type, 1): # temp
				neighbor.target_rooms.append(self)
				augments.append(neighbor)
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
