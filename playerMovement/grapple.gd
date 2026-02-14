extends Line2D
class_name Grapple

@onready var player: PlayerCharacter = $".."
@export var grapple_speed = 400

var grapple_position : Vector2
var min_grapple_dist = 5

func wants_grapple():
	if player.seat:
		return false
	if Input.is_action_pressed("grapple"):
		return true
	return false

func velocity(delta : float):
	if at_destination:
		return Vector2.ZERO
	return direction() * grapple_speed * delta

func direction():
	var grapple_dir = (grapple_position - global_position)
	if grapple_dir.length() > 1:
		grapple_dir.normalized() 
	return grapple_dir


var at_destination:
	get:
		var grapple_vector = (grapple_position - player.global_position)
		return grapple_vector.length() < min_grapple_dist

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("grapple"):
		grapple_position = get_global_mouse_position()
	if not wants_grapple():
		visible = false
		return
	
	visible = true
	set_point_position(0, Vector2.ZERO)
	set_point_position(1, to_local(grapple_position))
