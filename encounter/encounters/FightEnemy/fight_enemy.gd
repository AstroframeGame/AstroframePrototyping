extends Node2D
class_name FightEnemyEncounter
@onready var spawn: Marker2D = $Spawn

const PLAYER_SYSTEM = preload("res://playerMovement/player_system.tscn")

func _ready() -> void:
	name = "FightEnemy"
	MenuManager.open_menu("Game")
	GameManager.game_start.emit(self)
	MusicManager.play_gameplay()
	load_player_ship()

func _on_warp_pressed() -> void:
	GameManager.open_map()

var player_ship : Ship = null
func load_player_ship() -> void:
	var new_ship = SaveLoad.SHIP_PREFAB.instantiate()
	add_child(new_ship)
	player_ship = new_ship
	var player_system = PLAYER_SYSTEM.instantiate()
	player_ship.add_child(player_system)
	player_ship.global_position = spawn.global_position
	
	var real_path = ProjectSettings.globalize_path(GameManager.saves_folder)
	DirAccess.make_dir_recursive_absolute(real_path)
	
	SaveLoad.load_json(real_path, GameManager.continue_ship_name, new_ship)
