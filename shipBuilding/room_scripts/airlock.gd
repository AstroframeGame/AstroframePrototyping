class_name Airlock
extends Room

#func _ready() -> void:
	#super._ready()

func on_door_interact(player : PlayerCharacter):
	print(player.ship, ship)
	if player.ship == ship:
		player.on_ship_exit()
		ship.on_airlock_interaction.emit(player, false)
	else:
		player.on_ship_enter(ship)
		ship.on_airlock_interaction.emit(player, true)
