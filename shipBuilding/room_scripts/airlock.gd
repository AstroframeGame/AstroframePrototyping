class_name Airlock
extends Room

#func _ready() -> void:
	#super._ready()

func on_door_interact(player : Player):
	print(player.ship_in, ship)
	if player.ship_in == ship:
		player.on_ship_exit()
	else:
		player.on_ship_enter(ship)
