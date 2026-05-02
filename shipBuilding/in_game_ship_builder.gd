extends Node2D
class_name InGameShipBuilder

@onready var game_manager : GameManager = get_tree().root.get_node("Hub").get_node("GameManager")

func _ready() -> void:
	name = "InGameBuilder"
	# @alejandro why is this here?

func _on_warp_pressed() -> void:
	$ShipBuilding/SaveManager.save_json_path(game_manager.current_ship_folder, game_manager.current_ship_name)
	game_manager.load_queued();
	
