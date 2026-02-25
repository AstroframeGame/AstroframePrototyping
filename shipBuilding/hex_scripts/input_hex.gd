extends Area2D
class_name PowerInHex

@onready var room : Room = $"../.."
@onready var icon: Sprite2D = $"../Torus"

signal on_clicked(power_hex)

var is_powered : bool:
	get:
		if room and room.ship:
			return room.ship.power_links.find_key(self) != null
		return false

# called in add room
func update_state():
	if not icon:
		icon = $"../Torus"
	icon.self_modulate = Color("8effa8ff") if is_powered else Color("ec0083ff")
	
func _input_event(_viewport: Viewport, _event: InputEvent, _shape_idx: int) -> void:
	if not room.ship.my_character_inside():
		return
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		on_clicked.emit(self)

func interact(_player : PlayerCharacter) -> void:
	if not room is Room:
		return
	if not room.ship.my_character_inside():
		return
	on_clicked.emit(self)
