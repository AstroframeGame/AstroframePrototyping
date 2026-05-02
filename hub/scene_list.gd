extends VBoxContainer

const UNSTYLED = preload("res://hub/ui-themes/unstyled.tres")


@export_file("*.tscn") var scene_paths: Array[String]
func _ready() -> void:
	
	for path in scene_paths:
		var btn = Button.new()
		btn.theme = UNSTYLED
		var name_source = path
		if path.begins_with("uid://"):
			var id = ResourceUID.text_to_id(path)
			name_source = ResourceUID.get_id_path(id)
		btn.text = name_source.get_file().get_basename()
		btn.pressed.connect(_on_btn_pressed.bind(path))
		add_child(btn)


func _on_btn_pressed(path: String) -> void:
	#load_scene(path)
	GameManager.load_scene(path)
