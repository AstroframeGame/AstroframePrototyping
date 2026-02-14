extends Line2D
class_name Grapple

@onready var player: PlayerCharacter = $".."
@export var grapple_speed = 400

var attached_body : Node2D
var attached_offset : Vector2
var min_grapple_dist = 5

var grapple_position : Vector2:
	get:
		if is_instance_valid(attached_body):
			return attached_body.to_global(attached_offset)
		return global_position

func wants_grapple():
	if player.seat:
		return false
	if Input.is_action_pressed("grapple") and is_instance_valid(attached_body):
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
		return global_position.distance_to(grapple_position) < min_grapple_dist

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("grapple"):
		fire_grapple()
		
	if not wants_grapple():
		visible = false
		attached_body = null
		return
	
	visible = true
	set_point_position(0, Vector2.ZERO)
	set_point_position(1, to_local(grapple_position))

func fire_grapple():
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(global_position, get_global_mouse_position())
	query.exclude = [player]
	
	var result = space_state.intersect_ray(query)
	if result:
		attached_body = result.collider
		attached_offset = attached_body.to_local(result.position)
