extends Label

func _process(_delta):
	text = ""
	text += "fps: " + str(Engine.get_frames_per_second())
