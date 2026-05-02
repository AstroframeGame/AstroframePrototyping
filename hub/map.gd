extends CanvasLayer
class_name Map

const UNSTYLED = preload("res://hub/ui-themes/unstyled.tres")

@onready var game_manager : GameManager = $"../../GameManager"
@onready var button_container = $VBoxContainer

@export var scene_paths: Array[String]

func _ready() -> void:
	
	for path in scene_paths:
		var btn = Button.new()
		btn.theme = UNSTYLED
		var name_source = path
		if path.begins_with("uid://"):
			var id = ResourceUID.text_to_id(path)
			name_source = ResourceUID.get_id_path(id)
		btn.text = name_source.get_file().get_basename()
		btn.pressed.connect(start_level.bind(path))
		button_container.add_child(btn)

func generate_map():
	pass
	
func start_level(level_path : String):
	game_manager.queued_scene = level_path
	game_manager.load_scene("res://shipBuilding/in_game_ship_builder.tscn")
	
	
