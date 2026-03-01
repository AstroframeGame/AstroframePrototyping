class_name PlayerGun
extends Sprite2D

@onready var player: PlayerCharacter = $".."
@onready var marker_2d: Marker2D = $Marker2D
@onready var gunSprite : Sprite2D = $"."
@onready var shield_check : Area2D = $ShieldCheck

const bullet = preload("res://turretInteractions/Prefabs/projectile.tscn")

var accuracy: float = 0.6
var accur_low: float = 0.6
var accur_high: float = 1.0
var time_since_shot: float = 0

var damage: int = 5
var bullet_speed: int = 500 # @Alejandro can you add types to all variables, so that they match the projectile init() parameters

var holstered: bool = false

func _ready() -> void:
	holster()

func _process(delta: float) -> void:
	if (!holstered):
		look_at(get_global_mouse_position())
	
	time_since_shot += delta
	if time_since_shot > 0.5:
		accuracy = max(accuracy - (0.075 * delta), accur_low)
	

func shoot_bullet() -> void:
	if time_since_shot < .2:
		return
		
	if holstered:
		return
		
	var bullet_spread = deg_to_rad(46.0) * (1.0 - accuracy)
	var new_bullet : Projectile = bullet.instantiate()
	new_bullet.initialize(gunSprite, player.velocity, bullet_speed, Vector2.from_angle(gunSprite.global_rotation + randf_range(-bullet_spread, bullet_spread)), marker_2d.global_position, damage)
	new_bullet.collision_mask = player.collision_mask
	for body in shield_check.get_overlapping_bodies():
		if body is Shield:
			new_bullet.add_collision_exception_with(body)
	
	time_since_shot = 0
	accuracy = min(accuracy + (0.05), accur_high)
	SfxManager.play_sfx("laser_small")
	ProjectileManager.add_child(new_bullet)
		
func holster() -> void:
	visible = false
	holstered = true

func unholster() -> void:
	visible = true
	holstered = false

func get_holstered() -> bool:
	return holstered

func toggle_holster() -> void:
	if get_holstered():
		unholster()
	else:
		holster()
