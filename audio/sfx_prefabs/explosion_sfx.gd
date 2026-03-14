extends AudioStreamPlayer2D

# use audiostream polyphonic
# hold stream var here preloaded
# start random pitches

func play_quantity(fx : AudioStream, times : int = 1):
	await ready
	for i in range(min(times, max_polyphony)):
		var polyphonic : AudioStreamPlaybackPolyphonic = get_stream_playback() as AudioStreamPlaybackPolyphonic
		if fx and polyphonic:
			var pitch_mod = randf_range(-0.2,0.2)
			var volume_mod = randf_range(-2,2)
			var time_mod = randf_range(0, 5)
			polyphonic.play_stream(fx, i * time_mod,volume_mod,1.2 + pitch_mod, AudioServer.PLAYBACK_TYPE_DEFAULT, "SFX")
		else:
			push_warning("SFX tried to play but was not loaded")
		
func _ready() -> void:
	finished.connect(destroy)
	play()

func destroy():
	queue_free()
