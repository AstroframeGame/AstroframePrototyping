extends Node

@onready var menu: AudioStreamPlayer = $MenuMusic
@onready var ambient: AudioStreamPlayer = $GameAmbient
@onready var tense: AudioStreamPlayer = $GameTense

var _tween: Tween

signal on_mute_state_change(state : bool) # audioserver takes a frame to update.
var muted : bool :
	set(value):
		var bus_index = AudioServer.get_bus_index("Music")
		AudioServer.set_bus_mute(bus_index, value)
		on_mute_state_change.emit(value)
	get:
		var bus_index = AudioServer.get_bus_index("Music")
		return AudioServer.is_bus_mute(bus_index)

func play_menu():
	menu.bus = "Music"
	ambient.bus = "Music"
	tense.bus = "Music"
	_crossfade(menu, [ambient, tense])

func play_gameplay():
	if not ambient.playing:
		ambient.play()
		tense.play()
		ambient.volume_db = -80
		tense.volume_db = -80
	
	_crossfade(ambient, [menu, tense])

func change_level_music(new_ambient: AudioStream, new_tense: AudioStream, fade_time: float = 2.0):
	if ambient.stream == new_ambient and tense.stream == new_tense:
		return

	if _tween: _tween.kill()
	_tween = create_tween()
	
	_tween.parallel().tween_property(ambient, "volume_db", -80.0, fade_time)
	_tween.parallel().tween_property(tense, "volume_db", -80.0, fade_time)
	
	_tween.tween_callback(func(): _swap_tracks(new_ambient, new_tense, fade_time))

func _swap_tracks(new_ambient: AudioStream, new_tense: AudioStream, fade_time: float):
	ambient.stop()
	tense.stop()
	
	ambient.stream = new_ambient
	tense.stream = new_tense
	
	ambient.play()
	tense.play()
	
	ambient.volume_db = -80.0
	tense.volume_db = -80.0
	
	if _tween: _tween.kill()
	_tween = create_tween()
	
	_tween.tween_property(ambient, "volume_db", 0.0, fade_time)

func set_tense_mode(is_tense: bool):
	if _tween: _tween.kill()
	_tween = create_tween()
	
	var a_vol = -80.0 if is_tense else 0.0
	var t_vol = 0.0 if is_tense else -80.0
	
	_tween.set_parallel(true)
	_tween.set_trans(Tween.TRANS_SINE)
	_tween.tween_property(ambient, "volume_db", a_vol, 1.0).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_property(tense, "volume_db", t_vol, 1.0).set_ease(Tween.EASE_IN_OUT)

func _crossfade(to: AudioStreamPlayer, from: Array[AudioStreamPlayer]):
	if _tween: _tween.kill()
	_tween = create_tween()
	
	if not to.playing: 
		to.volume_db = -80.0
		to.play()
	
	_tween.set_parallel(true)
	_tween.set_trans(Tween.TRANS_SINE)
	
	_tween.tween_property(to, "volume_db", 0.0, 2.0).set_ease(Tween.EASE_OUT)
	
	for p in from:
		if p.playing:
			_tween.tween_property(p, "volume_db", -80.0, 2.0).set_ease(Tween.EASE_IN)
