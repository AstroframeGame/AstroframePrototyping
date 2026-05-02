extends Node
#class_name GameManager

const MAIN_MENU = preload("res://hub/main_menu.tscn")
const MAP = preload("res://hub/map.tscn")

signal game_start(world : Node2D)
signal game_quit()
signal queue_scene(scene_path: String)
var queued_scene: String 

var continue_ship_name : String = "continue_ship"
var continue_game_name : String = "continue"
var saves_folder : String = "user://saves/"

func _ready() -> void:
	# load settings
	# settings include whether or not game is muted
	# debug setting it muted for now
	MusicManager.muted = "dev" in OS.get_cmdline_args()
	MusicManager.play_menu()
	
	queue_scene.connect(_on_queue_scene)
	
func load_scene(path : String)->void:
	var packed_scene = await MenuManager.load_scene(path)
	MenuManager.open_menu("Game")
	get_tree().change_scene_to_packed(packed_scene)


func open_main_menu():
	game_quit.emit()
	get_tree().change_scene_to_packed(MAIN_MENU)
	MusicManager.play_menu()

@onready var dialogue_runner: DialougeRunner = MenuManager.get_node("Game/DialogueRunner")

func _on_settings_pressed() -> void:
	MenuManager.open_menu("Settings")

func menu_back():
	if MenuManager.open_menu("Game"):
		MenuManager.open_menu("Paused")
	else:
		open_main_menu()
	
func resume_game():
	MenuManager.open_menu("Game")

func open_map() -> void:
	get_tree().change_scene_to_packed(MAP)
	
func _on_queue_scene(scene_path: String) -> void:
	queued_scene = scene_path
	
func load_queued() -> void:
	load_scene(queued_scene)

func new_game():
	open_map()

func load_game():
	pass
	
func has_load_data() -> bool:
	var progress := FileAccess.file_exists(saves_folder + continue_game_name + ".json")
	var ship := FileAccess.file_exists(saves_folder + continue_ship_name + ".json")
	return progress and ship
