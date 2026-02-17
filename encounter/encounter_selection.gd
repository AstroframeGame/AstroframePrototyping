extends Node2D

@onready var encounter_list = $CanvasLayer/EncounterList
@onready var game_manager : GameManager = get_tree().root.get_node("Hub").get_node("GameManager")

@export_file("*.tscn") var encounter_paths: Array[String]

func _ready():
	name = "EncounterSelection"
	
	# DEMO menu to enter an encounter
	for path in encounter_paths:
		var btn = Button.new()
		var name_source = path
		if path.begins_with("uid://"):
			var id = ResourceUID.text_to_id(path)
			name_source = ResourceUID.get_id_path(id)
		btn.text = name_source.get_file().get_basename()
		btn.pressed.connect(_on_btn_pressed.bind(path))
		encounter_list.add_child(btn)

func _on_btn_pressed(path: String) -> void:
	encounter_list.visible = false
	game_manager.load_scene(path)
