extends AudioStreamPlayer2D

# use audiostream polyphonic
# hold stream var here preloaded
# start random pitches

func play_quantity(times : int = 1):
	await ready
	for i in range(min(times, max_polyphony)):
		play(0.11)

func _ready() -> void:
	finished.connect(destroy)

func destroy():
	queue_free()
