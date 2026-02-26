class_name AudioLibrary
extends Resource

@export var sound_effects: Dictionary[String, AudioStream]

func get_audio_stream(name: String):
	if name in sound_effects:
		return sound_effects[name]
	else:
		print(name + " sound effect not found")
	return null
