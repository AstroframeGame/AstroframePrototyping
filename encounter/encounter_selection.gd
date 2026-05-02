extends Node2D

@onready var options_list = $CanvasLayer/Options
@onready var back_btn = $CanvasLayer/Options/BackButton
@onready var encounter_list = $CanvasLayer/Options/EncounterList

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
		
	GameManager.game_quit.connect(_on_back_pressed)

func _exit_tree() -> void:
	for child in encounter_list.get_children():
		child.queue_free()

func _on_back_pressed() -> void:
	back_btn.visible = false
	encounter_list.visible = true
	if GameManager.current_scene and GameManager.current_scene != self:
		GameManager.current_scene.queue_free()
		GameManager.current_scene = self
		GameManager.game_quit.emit()


signal queued_scene(scene_path: String)
func _on_btn_pressed(path: String) -> void:
	back_btn.visible = true
	encounter_list.visible = false
	
	queued_scene.emit(path)
	GameManager.load_scene(path)
