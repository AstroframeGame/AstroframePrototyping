class_name MenuManager
extends Node

# the current open menu
@export var open : NodePath

func _ready() -> void:
	for n in get_children():
		n.visible = false
	get_node(open).visible = true

func is_open(menu_name : String):
	return open == NodePath(menu_name)

func open_menu(menu_name : String):
	#print("Menu: Opened " + menu_name)
	get_node(open).visible = false
	open = NodePath(menu_name)
	get_node(open).visible = true
	if menu_name == "Main": # can be done more cleanly
		CursorManager.reset_cursor()
	
# returns packed_scene
func load_scene(scene_path):
	open_menu("Loading")
	ResourceLoader.load_threaded_request(scene_path)
	var progress = []
	var status = ResourceLoader.load_threaded_get_status(scene_path, progress)
	
	while status != ResourceLoader.THREAD_LOAD_LOADED: 
		await get_tree().process_frame
		status = ResourceLoader.load_threaded_get_status(scene_path, progress)
		#$"Loading/VBoxContainer/Progress".text = str(round(progress[0] * 100)) + "%"
		$Loading/LoadProgress.value = progress[0] * 100
	
	var packed_scene = ResourceLoader.load_threaded_get(scene_path)
	return packed_scene

func load_scene_in_bg(scene_path):
	ResourceLoader.load_threaded_request(scene_path)
	var progress = []
	var status = ResourceLoader.load_threaded_get_status(scene_path, progress)
	
	while status != ResourceLoader.THREAD_LOAD_LOADED: 
		await get_tree().process_frame
		status = ResourceLoader.load_threaded_get_status(scene_path, progress)
	
	var packed_scene = ResourceLoader.load_threaded_get(scene_path)
	return packed_scene



# TODO
# if playing, return to gameplay
# if in main menu, back to main
func menu_back():
	open_menu("Main")
