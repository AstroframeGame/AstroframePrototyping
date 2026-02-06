extends Area2D
class_name PowerOutHex

@onready var room : Room = $"../.."
#@onready var power_line: Line2D = $PowerLine
@onready var icon: Sprite2D = $"../Dot"

var selecting = false

signal on_clicked(power_hex)

func _ready() -> void:
	on_clicked.connect(room.ship.toggle_power)
	update_state(is_powering)

var is_powering : bool:
	get:
		return room.ship.power_links.has(self)

func update_state(powered : bool):
	# grey  383838
	# red   942532
	# green 478d55
	icon.self_modulate = Color("478d55") if powered else Color("942532")

func _input_event(_viewport: Viewport, _event: InputEvent, _shape_idx: int) -> void:
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		#print(name, "clicked")
		on_clicked.emit(self)
		
