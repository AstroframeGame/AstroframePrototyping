extends Node
class_name GameManager

@onready var load_progress: TextureProgressBar = $"../UI/Loading/LoadProgress"

var current_scene : Node
@onready var menus : MenuManager = $"../UI"

func _ready() -> void:
	menus.open_menu("Main")
	
func load_scene(path : String)->void:
	var packed_scene = await menus.load_scene(path)
	menus.open_menu("Game")
	current_scene = packed_scene.instantiate()
	add_child(current_scene)

func quit_to_list():
	current_scene.queue_free()
	menus.open_menu("Main")

@onready var dialogue_runner: DialougeRunner = $"../UI/Game/DialogueRunner"
