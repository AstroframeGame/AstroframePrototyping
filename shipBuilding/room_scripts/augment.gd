class_name Augment
extends Room

var target_rooms : Array[Room]

func initialize(grid:TileMapLayer) -> void:
	super.initialize(grid)

func _ready() -> void:
	super._ready()

# func to fill out target_rooms
# func to pair target_rooms
# func to decouple them
