extends Area2D


@onready var room : Room = $"../.."

func _input_event(viewport: Viewport, event: InputEvent, shape_idx: int) -> void:
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		print(name, "clicked")
