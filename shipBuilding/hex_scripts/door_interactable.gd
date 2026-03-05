class_name DoorInteractable
extends Hex

'''
If the player interacts with this door, the room decides what happens.
'''


func can_interact() -> bool:
	return room is Room
	
func interact_hint() -> String:
	var inside = false
	if room != null and room.ship != null and room.ship.my_character_inside():
		inside = true
	return "Exit Ship" if inside else "Enter Ship"

func interact(player : PlayerCharacter) -> void:
	if not can_interact():
		return
	if room.has_method("on_door_interact"):
		room.on_door_interact(player)

@onready var sfx: AudioStreamPlayer2D = $ShieldSFX

func play_sfx(sound: AudioStream):
	var polyphonic : AudioStreamPlaybackPolyphonic = sfx.get_stream_playback() as AudioStreamPlaybackPolyphonic
	polyphonic.play_stream(sound, 0,0,1, AudioServer.PLAYBACK_TYPE_DEFAULT, "SFX")
