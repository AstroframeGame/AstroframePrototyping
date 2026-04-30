extends Node
class_name GameManager

@onready var multiplayer_manager: MultiplayerManager = $"../MultiplayerManager"

var player : PlayerCharacter:
	get:
		return $"../MultiplayerManager/PlayerCharacter"

@onready var load_progress: TextureProgressBar = $"../UI/Loading/LoadProgress"

var current_scene : Node2D
@onready var menus : MenuManager = $"../UI"
var in_game : bool = false

signal game_start(world : Node2D)
signal game_quit()
signal queue_scene(scene_path: String)
var queued_scene: String 

func _ready() -> void:
	menus.open_menu("Main")
	# load settings
	# settings include whether or not game is muted
	# debug setting it muted for now
	MusicManager.muted = "dev" in OS.get_cmdline_args()
	MusicManager.play_menu()
	
	queue_scene.connect(_on_queue_scene)
	
func load_scene(path : String)->void:
	var packed_scene = await menus.load_scene(path)
	menus.open_menu("Game")
	in_game = true
	current_scene = packed_scene.instantiate()
	add_child(current_scene)
	if current_scene.name == "ShipBuilding" or current_scene.name == "EncounterSelection" or current_scene.name == "InGameBuilder":
		return # skip the player on building scene and on encounter selector scene
	game_start.emit(current_scene)
	MusicManager.play_gameplay()

func start_game():
	pass

func new_game():
	pass

func load_game():
	pass

func open_singleplayer():
	# demo scene
	load_scene("res://encounter/encounters/__DEMO_LOCATION/0_1_DEMO/0_1_DEMO.tscn")

func open_ship_editor():
	load_scene("res://shipBuilding/ship_building.tscn")

func quit_to_list():
	game_quit.emit()
	if current_scene:
		current_scene.queue_free()
	menus.open_menu("Main")
	in_game = false
	MusicManager.play_menu()

func quit_application():
	get_tree().quit()

@onready var dialogue_runner: DialougeRunner = $"../UI/Game/DialogueRunner"


func _on_settings_pressed() -> void:
	menus.open_menu("Settings")

func menu_back():
	if in_game:
		menus.open_menu("Paused")
	else:
		quit_to_list()
	
func resume_game():
	menus.open_menu("Game")


func _on_btn_pressed() -> void:
	pass # Replace with function body.


func _on_map_pressed() -> void:
	menus.open_menu("Map")
	pass # Replace with function body.
	
func _on_queue_scene(scene_path: String) -> void:
	queued_scene = scene_path
	
func load_queued() -> void:
	current_scene.queue_free()
	load_scene(queued_scene)
