class_name MenuManager
extends Node

# the current open menu
@export var open : NodePath
@onready var game_manager: GameManager = $"../GameManager"

func _ready() -> void:
	for n in get_children():
		if n is CanvasLayer:
			n.visible = false
	get_node(open).visible = true
	InputHelper.switch_input_device.connect(focus_first_button)
	
	var settings_menu = $Settings/SettingsMenu
	if settings_menu:
		settings_menu.language_changed.connect(update_ui_labels)
	update_ui_labels(0)

func is_open(menu_name : String):
	return open == NodePath(menu_name)

func open_menu(menu_name : String):
	#print("Menu: Opened " + menu_name)
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
		#$Loading/LoadProgress/Label.text = "Progress - " + str(round(progress[0] * 100)) + "%"
		#$Loading/Label2.text = $Loading/LoadProgress/Label.text
		
	var packed_scene = ResourceLoader.load_threaded_get(scene_path)
	return packed_scene

@onready var asset_load_progress: TextureProgressBar = $"../Profiling/AssetLoadProgress"
func load_asset(scene_path):
	ResourceLoader.load_threaded_request(scene_path)
	var progress = []
	var status = ResourceLoader.load_threaded_get_status(scene_path, progress)
	
	while status != ResourceLoader.THREAD_LOAD_LOADED: 
		await get_tree().process_frame
		status = ResourceLoader.load_threaded_get_status(scene_path, progress)
		asset_load_progress.visible = true
		asset_load_progress.value = progress[0] * 100
	asset_load_progress.visible = false
	var packed_scene = ResourceLoader.load_threaded_get(scene_path)
	return packed_scene


func pause_game():
	open_menu("Paused")
	focus_first_button()	
func unpause_game():
	open_menu("Game")
	#focus_first_button()
func _unhandled_input(_event: InputEvent) -> void:
	if not (is_open("Paused") or is_open("Game") or is_open("Settings")):
		return
	if Input.is_action_just_pressed("pause"):
		if is_open("Paused"):
			unpause_game()
		elif is_open("Settings"):
			game_manager.menu_back()
		else:
			pause_game()
			
#region localization
@onready var play 		= $Main/VBoxContainer/Play
@onready var join 		= $Main/VBoxContainer/Multiplayer/Join
@onready var host 		= $Main/VBoxContainer/Multiplayer/Host
@onready var prompt 	= $Main/VBoxContainer/Multiplayer/IDPrompt
@onready var editor 	= $Main/VBoxContainer/Editor
@onready var settings 	= $Main/VBoxContainer/Settings
@onready var credits 	= $Main/VBoxContainer/Credits
@onready var quit 		= $Main/VBoxContainer/Quit
@onready var pause		= $Paused/VBoxContainer/PauseLabel
@onready var resume		= $Paused/VBoxContainer/ResumeGame
@onready var p_settings	= $Paused/VBoxContainer/PauseSettings
@onready var p_exit		= $Paused/VBoxContainer/Exit
@onready var game_over	= $GameOver/GameOverLabel
@onready var go_back	= $GameOver/GameOverBack
@onready var creds_back	= $Credits/Back
@onready var setts_back	= $Settings/Back

@onready var all_buttons = [
	play, join, host, prompt, editor, settings, credits, quit,
	pause, resume, p_settings, p_exit, game_over, go_back,
	]
const languages = ["en", "ja", "es"]
func update_ui_labels(index):
	TranslationServer.set_locale(languages[index])
	
	for button in all_buttons:
		button.text = tr(button.name)
#endregion
