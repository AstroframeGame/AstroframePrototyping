extends Room
class_name Shields_Room

#@export var recharge_speed = 30
@export var recharge_speeds := [-1, 7.5, 5, 2.5]
@export var max_shield_durability := [100,100,150,200]

@onready var shield: Shield = $Shield
@onready var recharge_timer : Timer = $RechargeTimer

@onready var sfx: AudioStreamPlayer2D = $AudioStreamPlayer2D
const SHIELDS_DOWN = preload("res://audio/sfx/shields_down.wav")
const CHARGE_SHORT = preload("res://audio/sfx/charge_short.wav")


func  _ready() -> void:
	super._ready()
	sfx.play()
	shield.on_shield_broken.connect(broken_sfx)
	shield.on_shield_started.connect(charge_sfx)
	
	on_power_level_change.connect(on_power_change)
	shield.on_shield_broken.connect(recharge_shield)
	recharge_timer.timeout.connect(deploy_shield)
	
	on_power_change(self)
	
	shield.durability = max_shield_durability[0]

func on_power_change(_room):
	if is_multiplayer_authority():
		if recharge_timer.time_left <= 0:
			shield.set_active(power_level > 0)	
		var durability_ratio = shield.durability / max_shield_durability[power_level]
		shield.durability = durability_ratio * max_shield_durability[power_level]
		
		sync_power_change.rpc(shield.get_path())

@rpc("authority", "call_local", "reliable")
func sync_power_change(sh: NodePath):
	if not is_multiplayer_authority():
		var shield_node = get_node_or_null(sh) as Shield
		if not shield_node:
			push_warning("[shields.gd/power_change()]: Shield path is incorrect.")
			return
		shield = shield_node

func recharge_shield():
	recharge_timer.start(recharge_speeds[power_level])

func deploy_shield():
	shield.durability = max_shield_durability[power_level]
	shield.set_active(power_level > 0)

func broken_sfx():
	play_sfx(SHIELDS_DOWN)
func charge_sfx():
	play_sfx(CHARGE_SHORT)
func play_sfx(fx):
	if not sfx:
		return
	var polyphonic : AudioStreamPlaybackPolyphonic = sfx.get_stream_playback() as AudioStreamPlaybackPolyphonic
	if fx and polyphonic:
		polyphonic.play_stream(fx, 0,0,1, AudioServer.PLAYBACK_TYPE_DEFAULT, "SFX")
	else:
		push_warning("SFX tried to play but was not loaded")
