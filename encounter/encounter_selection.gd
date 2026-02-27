extends Node2D

@onready var options_list = $CanvasLayer/Options
@onready var back_btn = $CanvasLayer/Options/BackButton
@onready var encounter_list = $CanvasLayer/Options/EncounterList

@onready var game_manager : GameManager = get_tree().root.get_node("Hub").get_node("GameManager")

@export_file("*.tscn") var encounter_paths: Array[String]

func _ready():
	name = "EncounterSelection"
	
	back_btn.pressed.connect(_on_back_pressed)
	back_btn.visible = false
	
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
		
	game_manager.game_quit.connect(_on_back_pressed)

func _exit_tree() -> void:
	for child in encounter_list.get_children():
		child.queue_free()

func _on_back_pressed() -> void:
	back_btn.visible = false
	encounter_list.visible = true
	if game_manager.current_scene and game_manager.current_scene != self:
		game_manager.current_scene.queue_free()
		game_manager.current_scene = self
		game_manager.game_quit.emit()

func _on_btn_pressed(path: String) -> void:
	back_btn.visible = true
	encounter_list.visible = false
	game_manager.load_scene(path)
