class_name GunHex
extends Hex

const PROJECTILE = preload("uid://devin6bdbcbay") # funny uid lol

@onready var gunSprite : Sprite2D = $Sprite
@onready var shield_check : Area2D = $ShieldCheck
@onready var marker_2d: Marker2D = $Sprite/Marker2D
@onready var timer : Timer = $Timer
@export var cooldown : float = 0.2


@export var projectileSpeed = 1000

func _ready():
	timer.wait_time = cooldown

func shoot(damage : int):
	if timer.time_left > 0:
		return
	timer.start()
	
	var proj : Projectile = PROJECTILE.instantiate()
	# removed parent velocity room.ship.linear_velocity
	proj.initialize(gunSprite, Vector2.ZERO, projectileSpeed, Vector2.from_angle(gunSprite.global_rotation), marker_2d.global_position, damage)
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
	$ShootSFX.play(0.11)
