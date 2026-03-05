extends Node

var screenshot_path = "user://screenshots/"

func _input(event):
	if event.is_action_pressed("screenshot"):
		capture_screenshot()

func capture_screenshot():
	await RenderingServer.frame_post_draw
	var image = get_viewport().get_texture().get_image()
	var time = Time.get_datetime_dict_from_system()
	var file_name = "astroframe_screenshot_%04d%02d%02d_%02d%02d%02d.png" % [time.year, time.month, time.day, time.hour, time.minute, time.second]
	
	if OS.has_feature("web"):
		var buffer = image.save_png_to_buffer()
		JavaScriptBridge.download_buffer(buffer, file_name, "image/png")
		InGameConsole.log_message("Screenshot downloaded: " + file_name)
	else:
		var path = screenshot_path
		var real_path = ProjectSettings.globalize_path(path)
		DirAccess.make_dir_recursive_absolute(real_path)
		image.save_png(path + file_name)
		print("Image saved to " + real_path + file_name)
		InGameConsole.log_message("Image saved to " + real_path + file_name)
