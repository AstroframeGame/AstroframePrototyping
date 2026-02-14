extends Node

@onready var menu: AudioStreamPlayer = $MenuPlayer
@onready var ambient: AudioStreamPlayer = $GameAmbient
@onready var tense: AudioStreamPlayer = $GameTense

var _tween: Tween

func play_menu():
	_crossfade(menu, [ambient, tense])

func play_gameplay():
	if not ambient.playing:
		ambient.volume_db = -80
		tense.volume_db = -80
		ambient.play()
		tense.play()
	
	_crossfade(ambient, [menu, tense])

func set_tense_mode(is_tense: bool):
	var tween = create_tween()
	var a_vol = -80.0 if is_tense else 0.0
	var t_vol = 0.0 if is_tense else -80.0
	
	tween.parallel().tween_property(ambient, "volume_db", a_vol, 1.0)
	tween.parallel().tween_property(tense, "volume_db", t_vol, 1.0)

func _crossfade(to: AudioStreamPlayer, from: Array[AudioStreamPlayer]):
	if _tween: _tween.kill()
	_tween = create_tween()
	
	if not to.playing: to.play()
	
	_tween.parallel().tween_property(to, "volume_db", 0.0, 2.0)
	for p in from:
		_tween.parallel().tween_property(p, "volume_db", -80.0, 2.0)
