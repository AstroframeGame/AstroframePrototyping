class_name PlayerGun
extends Sprite2D
#Following Guide: https://www.youtube.com/watch?v=FcNQII-d5Pg
@onready var player: Player = $".."

@onready var marker_2d: Marker2D = $Marker2D
@onready var gunSprite : Sprite2D = $"."

const bullet = preload("res://turretInteractions/Prefabs/projectile.tscn")
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	look_at(get_global_mouse_position())

func shootBullet() -> void:
	var new_bullet : Projectile = bullet.instantiate()
	new_bullet.initialize(gunSprite, player.velocity)
	new_bullet.position = marker_2d.global_position
	new_bullet.target_position = (get_global_mouse_position() - marker_2d.global_position).normalized()

	# also ignore any players or things inisde ship?
	#proj.global_position = global_position # should this be changed to barrel position?
	#proj.rotation = gunSprite.global_rotation # moved to initialize
	
		
	var world = player.global_world
	world.get_node("Projectiles").add_child(new_bullet) # not most elegent way
