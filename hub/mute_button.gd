extends TextureButton

const UNMUTE = preload("res://hub/menu_icons/icons8-audio-64.png")
const MUTE = preload("res://hub/menu_icons/icons8-mute-64.png")

func _ready() -> void:
	pressed.connect(on_pressed)
	MusicManager.on_mute_state_change.connect(refresh)
	refresh(MusicManager.muted)

func on_pressed():
	MusicManager.muted = !MusicManager.muted
	# will trigger callback

# listens for callback
func refresh(state : bool):
	if state:
		texture_normal = MUTE
	else:
		texture_normal = UNMUTE
