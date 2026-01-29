class_name Airlock
extends Room

func _ready() -> void:
	super._ready()

func on_door_interact(player : Player):
	player.on_ship_enter(ship)
