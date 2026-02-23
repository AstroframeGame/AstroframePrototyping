extends MarginContainer

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
#endregion

#region Controls
#REMAPABLE CONTROLS GO HERE......
#endregion

#region Audio
@onready var master_volume_percent: Label = $SettingsTabs/Audio/VBoxContainer/MasterVolume/MasterVolumePercent
@onready var music_volume_percent: Label = $SettingsTabs/Audio/VBoxContainer/MusicVolume/MusicVolumePercent
@onready var sfx_volume_percent: Label = $SettingsTabs/Audio/VBoxContainer/SfxVolume/SfxVolumePercent

func _on_master_volume_changed(value: float) -> void:
	var bus_index = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_linear(bus_index, value)
	master_volume_percent.text = str(int(value)) + "%"

func _on_music_volume_changed(value: float) -> void:
	var bus_index = AudioServer.get_bus_index("Music")
	AudioServer.set_bus_volume_linear(bus_index, value)
	music_volume_percent.text = str(int(value)) + "%"

func _on_sfx_volume_changed(value: float) -> void:
	var bus_index = AudioServer.get_bus_index("SFX")
	AudioServer.set_bus_volume_linear(bus_index, value)
	sfx_volume_percent.text = str(int(value)) + "%"
#endregion
