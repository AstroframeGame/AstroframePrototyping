extends Sprite2D
#Following Guide: https://www.youtube.com/watch?v=FcNQII-d5Pg

@onready var marker_2d: Marker2D = $Marker2D
const bullet = preload("res://turretInteractions/Prefabs/projectile.tscn")
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	look_at(get_global_mouse_position())

func shootBullet() -> void:
	var new_bullet = bullet.instantiate()
	new_bullet.position = marker_2d.global_position
	new_bullet.target_position = (get_global_mouse_position() - marker_2d.global_position).normalized()
	
