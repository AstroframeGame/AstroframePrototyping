extends Area2D
class_name PowerOutHex

@onready var room : Room = $"../.."
#@onready var power_line: Line2D = $PowerLine
@onready var icon: Sprite2D = $"../Dot"

var selecting = false

signal on_clicked(power_hex)


func _ready() -> void:
	#if room and room.ship:
		#on_clicked.connect(room.ship.toggle_power)
	#else:
		#print_debug("Out hex has no room or ship.")
	update_state(is_powering)

var is_powering : bool:
	get:
		if room and room.ship:
			return room.ship.power_links.has(self)
		return false
		
func update_state(powered : bool):
	# grey  383838
	# red   942532
	# green 478d55
	icon.self_modulate = Color("8effa8ff") if powered else Color("ec0083ff")

func _input_event(_viewport: Viewport, _event: InputEvent, _shape_idx: int) -> void:
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		#print(name, "clicked")
		on_clicked.emit(self)
		
