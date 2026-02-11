extends Area2D

@onready var room : Room = $"../.."
@onready var power_line: Line2D = $PowerLine

var selecting = false

func _input_event(_viewport: Viewport, _event: InputEvent, _shape_idx: int) -> void:
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		#print(name, "clicked")
		selecting = !selecting

func _process(_delta: float) -> void:
	if not selecting:
		return
	power_line.set_point_position(1,to_local(get_global_mouse_position()))


# debug why its below others even tho z is high
