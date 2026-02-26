extends MarginContainer

@onready var in_game_menu: MarginContainer = $InGameMenu
@onready var settings_menu: TabContainer = $SettingsMenu

func _on_resume_pressed() -> void:
	in_game_menu.visible = false
	settings_menu.visible = false


func _on_settings_pressed() -> void:
	in_game_menu.visible = false
	settings_menu.visible = true


func _on_main_menu_pressed() -> void: #Not finished
	in_game_menu.visible = false
	settings_menu.visible = false
