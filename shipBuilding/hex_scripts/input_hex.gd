extends Area2D
class_name PowerInHex

@onready var room : Room = $"../.."
@onready var icon: Sprite2D = $"../Torus"

signal on_clicked(power_hex)

func _ready() -> void:
	if room and room.ship:
		on_clicked.connect(room.ship.toggle_power)
	else:
		print_debug("Input hex has no room or ship.")
	update_state(is_powered)

var is_powered : bool:
	get:
		if room and room.ship:
			return room.ship.power_links.find_key(self) != null
		return false

func update_state(powered : bool):
	icon.self_modulate = Color("8effa8ff") if powered else Color("ec0083ff")
	
func _input_event(_viewport: Viewport, _event: InputEvent, _shape_idx: int) -> void:
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		#print(name, "clicked")
		on_clicked.emit(self)
