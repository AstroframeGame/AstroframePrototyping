extends Node2D
class_name MainMenu

func _ready() -> void:
	MenuManager.open_menu($Main.get_path())
	if not GameManager.has_load_data():
		$Main/VBoxContainer/Continue.disabled = true

func continue_game():
	GameManager.load_game()

func new_game():
	GameManager.new_game()

func open_ship_editor():
	GameManager.load_scene("res://shipBuilding/ship_building.tscn")

func quit_application():
	get_tree().quit()

func open_settings():
	MenuManager.open_menu("Settings")

func open_credits():
	MenuManager.open_menu($Main/VBoxContainer/Credits.get_path())
