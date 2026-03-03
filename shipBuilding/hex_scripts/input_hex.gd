extends Hex
class_name PowerInHex

@onready var icon: Sprite2D = $"Torus"

signal on_clicked(power_hex)

var is_powered : bool:
	get:
		if room and room.ship:
			return room.ship.power_links.find_key(self) != null
		return false

# called in add room
func update_state():
	if not icon:
		icon = $"Torus"
	icon.self_modulate = Color("8effa8ff") if is_powered else Color("ec0083ff")
	
func _input_event(_viewport: Viewport, _event: InputEvent, _shape_idx: int) -> void:
	if not room.ship.my_character_inside():
		return
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		on_clicked.emit(self)


func can_interact() -> bool:
	return room is Room and room.ship.my_character_inside()
func interact_hint() -> String:
	return "Toggle Power " + ("Off" if is_powered else "On")
	
func interact(_player : PlayerCharacter) -> void:
	if not can_interact():
		return
	on_clicked.emit(self)
