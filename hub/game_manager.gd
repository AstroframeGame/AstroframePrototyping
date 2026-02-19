extends Node
class_name GameManager

@onready var multiplayer_manager: MultiplayerManager = $"../MultiplayerManager"

@onready var load_progress: TextureProgressBar = $"../UI/Loading/LoadProgress"

var current_scene : Node2D
@onready var menus : MenuManager = $"../UI"

signal game_start(world : Node2D)
signal game_quit()

func _ready() -> void:
	menus.open_menu("Main")
	
func load_scene(path : String)->void:
	var packed_scene = await menus.load_scene(path)
	menus.open_menu("Game")
	current_scene = packed_scene.instantiate()
	add_child(current_scene)
	if current_scene.name == "ShipBuilding":
		return # skip the player on building scene
	game_start.emit(current_scene)

@rpc("authority", "call_local", "reliable")
func load_scenes_across_peers(path):
	multiplayer_manager.curr_scene_path = path
	multiplayer_manager.is_in_scene = true
	load_scene(path)	

func start_game():
	pass

func new_game():
	pass

func load_game():
	pass

func quit_to_list():
	game_quit.emit()
	if current_scene:
		current_scene.queue_free()
	menus.open_menu("Main")

func quit_application():
	get_tree().quit()

@onready var dialogue_runner: DialougeRunner = $"../UI/Game/DialogueRunner"
