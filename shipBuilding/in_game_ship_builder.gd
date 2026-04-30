extends Node2D
class_name InGameShipBuilder

@onready var game_manager : GameManager = get_tree().root.get_node("Hub").get_node("GameManager")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_warp_pressed() -> void:
	game_manager.load_queued();
	pass
