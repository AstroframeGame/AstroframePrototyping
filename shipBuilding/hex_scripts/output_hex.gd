extends Area2D
class_name PowerOutHex

@onready var room : Room = $"../.."
@onready var power_line: Line2D = $PowerLine
@onready var icon: Sprite2D = $"../Dot"

var selecting = false

func update_state(powered : bool):
	# grey  383838
	# red   942532
	# green 478d55
	icon.self_modulate = Color("478d55") if powered else Color("942532")

func _input_event(_viewport: Viewport, _event: InputEvent, _shape_idx: int) -> void:
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		print(name, "clicked")
		selecting = !selecting

func _process(_delta: float) -> void:
	if not selecting:
		return
	power_line.set_point_position(1,to_local(get_global_mouse_position()))


# debug why its below others even tho z is high
