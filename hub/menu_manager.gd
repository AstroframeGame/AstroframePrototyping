#class_name MenuManager
extends Node

# the current open menu
@export var open : NodePath

func _ready() -> void:
	for n in get_children():
		if n is CanvasLayer:
			n.visible = false
	InputHelper.switch_input_device.connect(focus_first_button)

func is_open(menu_name : String):
	return open == NodePath(menu_name)

func open_menu(menu_name : String):
	#print("Menu: Opened " + menu_name)
	if get_node_or_null(open):
		get_node(open).visible = false
	open = NodePath(menu_name)
	get_node(open).visible = true
	if menu_name == "Main": # can be done more cleanly
		CursorManager.reset_cursor()
	if not is_open("Game"):
		focus_first_button()
	
func focus_first_button() -> void:
	if InputHelper.using_mouse:
		return
	var current_menu = get_node_or_null(open)
	if current_menu:
		var first_button = _find_first_button(current_menu)
		if first_button:
			first_button.grab_focus()

func _find_first_button(node: Node) -> Button:
	for child in node.get_children():
		if child is Button and child.is_visible_in_tree() and not child.disabled and child.focus_mode != Control.FOCUS_NONE:
			return child
		var found = _find_first_button(child)
		if found:
			return found
	return null
		
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
		$Loading/LoadProgress/Label.text = "Progress - " + str(round(progress[0] * 100)) + "%"
		$Loading/Label2.text = $Loading/LoadProgress/Label.text
		
	var packed_scene = ResourceLoader.load_threaded_get(scene_path)
	return packed_scene

func pause_game():
	open_menu("Paused")
	focus_first_button()
func unpause_game():
	open_menu("Game")
	#focus_first_button()
func open_settings():
	open_menu("Settings")
func quit_to_main_menu():
	GameManager.open_main_menu()
func back():
	pass

func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("debug_quit"):
		get_tree().quit()
	if not (is_open("Paused") or is_open("Game") or is_open("Settings")):
		return
	if Input.is_action_just_pressed("pause"):
		if is_open("Paused"):
			unpause_game()
		elif is_open("Settings"):
			GameManager.menu_back()
		else:
			pause_game()
