extends Hex
class_name PowerInHex

@onready var icon: Sprite2D = $"Torus"

signal on_clicked(power_hex)

var is_powered : bool:
	get:
		if room and room.ship:
			return room.ship.power_links.find_key(self) != null
		return false

# do not use this for reference
var _was_powered = false

# called in add room
func update_state():
	if _was_powered != is_powered:
		if is_powered:
			play_sfx(SFX_POWER_UP)
		else:
			play_sfx(SFX_POWER_DOWN)
		_was_powered = is_powered
	if not icon:
		icon = $"Torus"
	icon.self_modulate = Color("8effa8ff") if is_powered else Color("ec0083ff")
	
func _input_event(_viewport: Viewport, _event: InputEvent, _shape_idx: int) -> void:
	if not room.ship:
		return
	
	if not room.ship.my_character_inside():
		return
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		on_clicked.emit(self)
		

func can_interact() -> bool:
	if room is Room:
		if room.ship != null:
			if room.ship.my_character_inside():
				return true
	return false
func interact_hint() -> String:
	return "Toggle Power " + ("Off" if is_powered else "On")
	
func interact(_player : PlayerCharacter) -> void:
	if not can_interact():
		return
	on_clicked.emit(self)

func _ready() -> void:
	sfx.play()

@onready var sfx: AudioStreamPlayer2D = $AudioStreamPlayer2D
const SFX_POWER_UP = preload("res://audio/sfx/SfxAudioFileFolder/charge_short.wav")
const SFX_POWER_DOWN = preload("res://audio/sfx/SfxAudioFileFolder/shields_down.wav")

func play_sfx(fx):
	if not sfx:
		return
	var polyphonic : AudioStreamPlaybackPolyphonic = sfx.get_stream_playback() as AudioStreamPlaybackPolyphonic
	if fx and polyphonic:
		polyphonic.play_stream(fx, 0,0,1, AudioServer.PLAYBACK_TYPE_DEFAULT, "SFX")
	else:
		push_warning("SFX tried to play but was not loaded")
