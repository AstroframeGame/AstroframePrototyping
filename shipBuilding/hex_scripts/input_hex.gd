extends Area2D


@onready var room : Room = $"../.."

func _input_event(_viewport: Viewport, _event: InputEvent, _shape_idx: int) -> void:
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		#print(name, "clicked")
		pass
