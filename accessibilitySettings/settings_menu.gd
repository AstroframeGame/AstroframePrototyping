class_name SettingsMenu
extends MarginContainer

const UNSTYLED = preload("res://hub/ui-themes/unstyled.tres")
@onready var resolution_options: OptionButton = $SettingsTabs/Video/MarginContainer/VBoxContainer/ResolutionHBox/ResolutionOptions
@onready var key_mouse_binds: VBoxContainer = $"SettingsTabs/Controls/MarginContainer/ControlInterface/Keyboard&Mouse/VBoxContainer"
@onready var controller_binds: VBoxContainer = $SettingsTabs/Controls/MarginContainer/ControlInterface/Controller/VBoxContainer
@onready var game_layer: CanvasLayer = $"../../../../Game"

func _ready() -> void:
	set_dev_settings()
	generate_remap_settings()
	generate_resolution_options()

func set_dev_settings():
	if "dev" in OS.get_cmdline_args():
		_on_fullscreen_toggled(false)
		#get_window().set_size(Vector2(1152,648))
		get_window().set_size(Vector2(1920,1080))
		center_screen()
	

#region Video
var resolutions = {
	"3840x2160": Vector2i(3840,2160),
	"2560x1440": Vector2i(2560,1440),
	"1920x1080": Vector2i(1920,1080),
	"1600x900": Vector2i(1600,900),
	"1440x900": Vector2i(1440,900),
	"1366x768": Vector2i(1366,768),
	"1280x720": Vector2i(1280,720),
	"1024x600": Vector2i(1024,600),
	"800x600": Vector2i(800,600)
}

func generate_resolution_options():
	for res in resolutions:
		if resolutions[res][1] <= DisplayServer.screen_get_size()[1]:
			resolution_options.add_item(res)

func _on_resolution_option_selected(index: int) -> void:
	get_window().set_size(resolutions[resolution_options.get_item_text(index)])
	center_screen()

func _on_fullscreen_toggled(toggled_on: bool) -> void:
	if toggled_on:
		get_window().set_mode(Window.MODE_FULLSCREEN)
	else:
		get_window().set_mode(Window.MODE_WINDOWED)
		center_screen()

func center_screen():
	@warning_ignore("integer_division")
	var screen_center = DisplayServer.screen_get_position() + DisplayServer.screen_get_size() / 2
	var window_scale = Vector2i(get_window().get_size_with_decorations() / 2.0)
	get_window().set_position(screen_center - window_scale)
	
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
		var km_horiz_box = HBoxContainer.new()
		var contr_horiz_box = HBoxContainer.new()
		var km_lbl = Label.new()
		km_lbl.text = action
		km_lbl.add_theme_font_size_override("font_size", 30)
		km_horiz_box.add_child(km_lbl)
		var contr_lbl = Label.new()
		contr_lbl.text = action
		contr_lbl.add_theme_font_size_override("font_size", 30)
		contr_horiz_box.add_child(contr_lbl)
		var events = InputMap.action_get_events(action)
		for i in range(events.size()):
			var ev = events[i]
			if ev is InputEventJoypadButton or ev is InputEventJoypadMotion:
				var contr_btn = RemappableButton.new()
				contr_btn.add_theme_font_size_override("font_size", 30)
				var name_dict = null
				if ev is InputEventJoypadButton:
					name_dict = contr_btn.CONTROLLER_LABELS
					#contr_btn.text = name_dict[name_dict.keys()[ev.button_index]]
					contr_btn.action_type = "contr"
				elif ev is InputEventJoypadMotion:
					name_dict = contr_btn.MOTION_LABELS
					#print(ev.as_text())
					#print(ev.axis)
					#print()
					#contr_btn.text = name_dict[ev.as_text()]
					contr_btn.action_type = "contr"
				
				contr_btn.action_name = action
				contr_btn.event_index = i
				contr_horiz_box.add_child(contr_btn)
			
			elif ev is InputEventKey or ev is InputEventMouseButton:
				var km_btn = RemappableButton.new()
				km_btn.add_theme_font_size_override("font_size", 30)
				km_btn.action_name = action
				#km_btn.text = ev.as_text().get_slice(" - ", 0)
				km_btn.event_index = i
				km_horiz_box.add_child(km_btn)
				km_btn.action_type = "keyBrd"
			
			else:
				var bad_btn = RemappableButton.new()
				bad_btn.text = "Invalid Binding"
				km_horiz_box.add_child(bad_btn)
				contr_horiz_box.add_child(bad_btn)
		
		key_mouse_binds.add_child(km_horiz_box)
		controller_binds.add_child(contr_horiz_box)
#endregion

#region Audio
@onready var master_volume_percent: Label = $SettingsTabs/Audio/MarginContainer/VBoxContainer/HBoxContainer/MasterVolumePercent
@onready var music_volume_percent: Label = $SettingsTabs/Audio/MarginContainer/VBoxContainer/HBoxContainer2/MusicVolumePercent
@onready var sfx_volume_percent: Label = $SettingsTabs/Audio/MarginContainer/VBoxContainer/HBoxContainer3/SfxVolumePercent

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
