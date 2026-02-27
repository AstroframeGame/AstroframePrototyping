extends Hex
class_name PowerOutHex

@onready var icon: Sprite2D = $"Dot"

var is_powering : bool:
	get:
		if room and room.ship:
			return room.ship.power_links.has(self)
		return false

# called in add room
func update_state():
	# grey  383838
	# red   942532
	# green 478d55
	if not icon:
		icon = $"Dot"
	icon.self_modulate = Color("8effa8ff") if is_powering else Color("ec0083ff")
