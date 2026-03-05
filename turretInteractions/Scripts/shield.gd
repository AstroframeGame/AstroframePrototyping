class_name Shield
extends StaticBody2D

signal on_shield_started()
signal on_shield_broken()
#var SHIELDS_UP = preload("res://audio/sfx/SfxAudioFileFolder/charge_short.wav")
var SHIELDS_DOWN = preload("res://audio/sfx/SfxAudioFileFolder/shields_down.wav")

@onready var collider = $CollisionShape2D
@onready var ship = $"../.."

var durability : int

func _ready() -> void:
	sfx.play()

## smooth this later with a coroutine
func set_active(is_active : bool):
	if not visible and is_active:
		on_shield_started.emit()
	visible = is_active
	collider.disabled = not is_active

func take_damage(amount : int, vfx_pos:Vector2):
	durability -= amount
	ship.hit_vfx(vfx_pos)

func _process(_delta: float) -> void:
	if durability < 0:
		set_active(false)
		on_shield_broken.emit()
		durability = 0
		play_sfx(SHIELDS_DOWN)

@onready var sfx: AudioStreamPlayer2D = $ShieldSFX

func play_sfx(sound: AudioStream):
	var polyphonic : AudioStreamPlaybackPolyphonic = sfx.get_stream_playback() as AudioStreamPlaybackPolyphonic
	polyphonic.play_stream(sound, 0,0,1, AudioServer.PLAYBACK_TYPE_DEFAULT, "SFX")
