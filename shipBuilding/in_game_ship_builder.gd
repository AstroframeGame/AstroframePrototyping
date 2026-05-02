extends Node2D
class_name InGameShipBuilder

func _ready() -> void:
	name = "InGameBuilder"
	# @alejandro why is this here?

func _on_warp_pressed() -> void:
	$ShipBuilding/SaveManager.save_json_path(GameManager.saves_folder, GameManager.continue_ship_name)
	GameManager.load_queued();
	
