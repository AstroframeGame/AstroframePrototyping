extends Node

func _input(event):
	if event.is_action_pressed("screenshot"):
		capture_screenshot()

func capture_screenshot():
	var image = get_viewport().get_texture().get_image()
	var time = Time.get_datetime_dict_from_system()
	var file_name = "astroframe_screenshot_%04d%02d%02d_%02d%02d%02d.png" % [time.year, time.month, time.day, time.hour, time.minute, time.second]
	image.save_png("user://" + file_name)
	var real_path = ProjectSettings.globalize_path("user://" + file_name)
	print("Image saved to " + real_path)
	InGameConsole.log_message("Image saved to " + real_path)
