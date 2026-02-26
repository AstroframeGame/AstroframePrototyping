class_name PolyphonicSfxPlayer
extends AudioStreamPlayer2D

@export var audio_library: AudioLibrary
@export var max_poly: int = 32

var sfx_holder: Array[AudioStream] = folder_to_sfx("res://audio/sfx/SfxAudioFileFolder/")

func _ready() -> void:
	bus = "SFX"
	stream = AudioStreamPolyphonic.new()
	stream.polyphony = max_poly
	fill_audio_library(sfx_holder)
	
func play_sfx(_name: String) -> void:
	if _name:
		var sfx_stream = audio_library.get_audio_stream(_name)
		if !sfx_stream:
			return
		
		if !playing:
			play()
		var poly_playback = get_stream_playback()
		poly_playback.play_stream(sfx_stream)

func fill_audio_library(sfx_array: Array[AudioStream]):
	for sfx_stream in sfx_array:
		audio_library.sound_effects[sfx_stream.resource_path.get_file().get_basename()] = sfx_stream


func folder_to_sfx(path) -> Array[AudioStream]:
	var sfx_array: Array[AudioStream] = []
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".import"):
				file_name = dir.get_next()
				continue
			sfx_array.push_back(load(path + file_name))
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the path")
	return sfx_array
