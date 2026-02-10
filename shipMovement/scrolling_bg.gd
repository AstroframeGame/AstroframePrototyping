extends ColorRect

func _process(_delta):
	var cam = get_viewport().get_camera_2d()
	if cam:
		material.set_shader_parameter("camera_offset", cam.global_position)
		material.set_shader_parameter("camera_zoom", cam.zoom.x)
