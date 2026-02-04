class_name PlayerGun
extends Sprite2D
#Following Guide: https://www.youtube.com/watch?v=FcNQII-d5Pg
@onready var player: Player = $".."
@onready var asteroids: Node2D = $"../../../Asteroids"
@onready var marker_2d: Marker2D = $Marker2D
@onready var gunSprite : Sprite2D = $"."

const bullet = preload("res://turretInteractions/Prefabs/projectile.tscn")

var accuracy = 0.6
var accur_low = 0.6
var accur_high = 1
var time_since_shot = 0

var damage = 5
var bulletSpeed = 500
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	look_at(get_global_mouse_position())
	
	time_since_shot += delta
	if time_since_shot > 0.5:
		accuracy = max(accuracy - (0.075 * delta), accur_low)
	



func shootBullet() -> void:
	if time_since_shot < .2:
		return
		
	var bullet_spread = deg_to_rad(46.0) * (1.0 - accuracy)
	
	var new_bullet : Projectile = bullet.instantiate()
	new_bullet.initialize(gunSprite, player.velocity, bulletSpeed, Vector2.from_angle(gunSprite.global_rotation + randf_range(-bullet_spread, bullet_spread)), marker_2d.global_position, damage)
	new_bullet.add_collision_exception_with(gunSprite)
	new_bullet.add_collision_exception_with(player)
	
	time_since_shot = 0
	accuracy = min(accuracy + (0.05), accur_high)

	# also ignore any players or things inisde ship?
	#proj.global_position = global_position # should this be changed to barrel position?
	#proj.rotation = gunSprite.global_rotation # moved to initialize
	
		
	var world = player.global_world
	assert(world.get_node("Projectiles") != null)
	world.get_node("Projectiles").add_child(new_bullet) # not most elegent way
