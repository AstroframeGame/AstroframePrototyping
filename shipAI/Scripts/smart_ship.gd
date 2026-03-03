extends Ship
class_name Smart_Ship

func _ready() -> void:
	super()
	pair_all_links()

func pair_all_links():
	for output_hex in get_available_power_out():
		for input_hex in get_available_power_in():
			if not input_hex.is_powered:
				power_links[output_hex] = input_hex
				output_hex.update_state()
				input_hex.update_state()
		
