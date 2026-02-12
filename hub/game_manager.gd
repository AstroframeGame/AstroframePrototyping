extends Node

@export_file("*.tscn") var scene_paths: Array[String]
@export var loading_screen_scene: PackedScene

@onready var scene_list: VBoxContainer = $"../UI/SceneList/ScrollContainer/SceneList"
@onready var load_progress: TextureProgressBar = $"../UI/Loading/LoadProgress"

var current_scene : Node

func _ready() -> void:
	$"../UI/Loading".visible = false
	$"../UI/InGame".visible = false
	$"../UI/SceneList".visible = true
	
	for path in scene_paths:
		var btn = Button.new()
		var name_source = path
		if path.begins_with("uid://"):
			var id = ResourceUID.text_to_id(path)
			name_source = ResourceUID.get_id_path(id)
		btn.text = name_source.get_file().get_basename()
		btn.pressed.connect(_on_btn_pressed.bind(path))
		scene_list.add_child(btn)

func _on_btn_pressed(path: String) -> void:
	load_scene(path)

func load_scene(path : String)->void:
	$"../UI/Loading".visible = true
	$"../UI/SceneList".visible = false
	ResourceLoader.load_threaded_request(path)
	var progress = []
	var status = ResourceLoader.load_threaded_get_status(path, progress)
	
	while status != ResourceLoader.THREAD_LOAD_LOADED:
		await get_tree().process_frame
		status = ResourceLoader.load_threaded_get_status(path, progress)
		load_progress.value = progress[0]
	#$Control/Label.text = str(int(progress[0] * 100)) + "%"
	
	if status == ResourceLoader.THREAD_LOAD_LOADED:
		var packed_scene = ResourceLoader.load_threaded_get(path)
		$"../UI/Loading".visible = false
		$"../UI/InGame".visible = true
		current_scene = packed_scene.instantiate()
		add_child(current_scene)

func quit_to_list():
	current_scene.queue_free()
	$"../UI/SceneList".visible = true
	$"../UI/InGame".visible = false

@onready var dialouge_runner: DialougeRunner = $"../UI/InGame/DialougeRunner"
