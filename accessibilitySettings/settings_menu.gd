class_name SettingsMenu
extends MarginContainer

const UNSTYLED = preload("res://hub/ui-themes/unstyled.tres")
@onready var key_mouse_binds: VBoxContainer = $"SettingsTabs/Controls/ControlInterface/Keyboard&Mouse/VBoxContainer"
@onready var game_layer: CanvasLayer = $"../../Game"

func _ready() -> void:
	generate_remap_settings()

#region Video
func _on_resoluton_option_selected(index: int) -> void:
	match index:
		0:
			DisplayServer.window_set_size(Vector2i(3840, 2160))
		1:
			DisplayServer.window_set_size(Vector2i(2560, 1440))
		2:
			DisplayServer.window_set_size(Vector2i(1920, 1080))
		3:
			DisplayServer.window_set_size(Vector2i(1280, 720))
		4:
			DisplayServer.window_set_size(Vector2i(640, 480))

func _on_fullscreen_toggled(toggled_on: bool) -> void:
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		
#region Accessibility
func _on_filter_option_selected(index: int) -> void:
	game_layer.set_color_mode(index)

#endregion
#endregion

#region Controls
func generate_remap_settings() -> void:
	var input_map = InputMap.get_actions()
	for action in input_map:
		if action.get_slice("_", 0) == "ui":
			continue
		var horiz_box = HBoxContainer.new()
		var lbl = Label.new()
		lbl.text = action
		var btn = RemappableButton.new()
		btn.action_name = action
		btn.theme = UNSTYLED
		var events = InputMap.action_get_events(action)
		if events.size() > 0:
			btn.text = events[0].as_text().get_slice(" - ", 0)
		else:
			btn.text = "No Binding"
		horiz_box.add_child(lbl)
		horiz_box.add_child(btn)
		key_mouse_binds.add_child(horiz_box)
#endregion

#region Audio
@onready var master_volume_percent: Label = $SettingsTabs/Audio/VBoxContainer/MasterVolume/MasterVolumePercent
@onready var music_volume_percent: Label = $SettingsTabs/Audio/VBoxContainer/MusicVolume/MusicVolumePercent
@onready var sfx_volume_percent: Label = $SettingsTabs/Audio/VBoxContainer/SfxVolume/SfxVolumePercent

func _on_master_volume_changed(value: float) -> void:
	var bus_index = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_linear(bus_index, value/100)
	master_volume_percent.text = str(int(value)) + "%"

func _on_music_volume_changed(value: float) -> void:
	var bus_index = AudioServer.get_bus_index("Music")
	AudioServer.set_bus_volume_linear(bus_index, value/100)
	music_volume_percent.text = str(int(value)) + "%"

func _on_sfx_volume_changed(value: float) -> void:
	var bus_index = AudioServer.get_bus_index("SFX")
	AudioServer.set_bus_volume_linear(bus_index, value/100)
	sfx_volume_percent.text = str(int(value)) + "%"
#endregion
