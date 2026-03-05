class_name GunHex
extends Hex

const PROJECTILE = preload("uid://devin6bdbcbay") # funny uid lol
const SFX_LASER_MEDIUM = preload("res://audio/sfx/laser_medium.wav")


@export var gunSprite : Node2D
@onready var shield_check : Area2D = $ShieldCheck
@export var barrel: Marker2D
@onready var timer : Timer = $Timer
@export var cooldown : float = 0.2


@export var projectileSpeed = 1000

func _ready():
	timer.wait_time = cooldown
	sfx.play() # start the sfx

func shoot(damage : int):
	if timer.time_left > 0:
		return
	timer.start()
	
	var proj : Projectile = PROJECTILE.instantiate()
	# removed parent velocity room.ship.linear_velocity
	proj.initialize(gunSprite, Vector2.ZERO, projectileSpeed, Vector2.from_angle(gunSprite.global_rotation), barrel.global_position, damage)
	proj.add_collision_exception_with(room.ship)
	proj.add_collision_exception_with(room.ship.get_node("Walls"))
	proj.owner_ship = room.ship
	
	for shield in room.ship.get_active_shields():
		if shield.visible:
			proj.add_collision_exception_with(shield)
	
	for body in shield_check.get_overlapping_bodies():
		if body is Shield:
			proj.add_collision_exception_with(body)
	# get multiplayer manager instead
	ProjectileManager.add_child(proj)
	play_sfx()

@onready var sfx: AudioStreamPlayer2D = $ShootSFX

func play_sfx():
	var polyphonic : AudioStreamPlaybackPolyphonic = sfx.get_stream_playback() as AudioStreamPlaybackPolyphonic
	polyphonic.play_stream(SFX_LASER_MEDIUM, 0,0,1, AudioServer.PLAYBACK_TYPE_DEFAULT, "SFX")
