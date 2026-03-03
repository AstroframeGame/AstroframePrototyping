extends Hex
class_name PowerInHex

@onready var icon: Sprite2D = $"Torus"

signal on_clicked(player: PlayerCharacter, power_hex: PowerInHex)

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

func interact(_player : PlayerCharacter) -> void:
	if is_multiplayer_authority():
		if not room is Room:
			return
		if not room.ship.my_character_inside():
			return
		on_clicked.emit(_player, self)
	else:
		var succeeded = room.ship.finished_power_process
		if succeeded:
			on_clicked.emit(_player, self)

func _physics_process(delta: float) -> void:
	update_state()
