extends Area2D
class_name PowerInHex

@onready var room : Room = $"../.."
@onready var icon: Sprite2D = $"../Torus"

signal on_clicked()

func _ready() -> void:
	room.ship

func update_state(powered : bool):
	icon.self_modulate = Color("478d55") if powered else Color("942532")
	
func _input_event(_viewport: Viewport, _event: InputEvent, _shape_idx: int) -> void:
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		print(name, "clicked")
