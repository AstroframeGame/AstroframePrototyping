extends Control

func _ready() -> void:
	load_player_ship()

var player_ship : Ship = null
func load_player_ship() -> void:
	var new_ship = SaveLoad.SHIP_PREFAB.instantiate()
	add_child(new_ship)
	player_ship = new_ship
	
	var real_path = ProjectSettings.globalize_path(GameManager.saves_folder)
	DirAccess.make_dir_recursive_absolute(real_path)
	
	SaveLoad.load_json(real_path, GameManager.continue_ship_name, new_ship)
