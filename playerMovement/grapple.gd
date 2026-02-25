extends Line2D
class_name Grapple

@onready var player: PlayerCharacter = $".."
@export var grapple_speed = 400
@export_flags_2d_physics var collision_mask = 257

var attached_body : Node2D
var attached_offset : Vector2
var min_grapple_dist = 5

var is_grappling := false
var will_grapple: bool = false
var mouse_pos: Vector2 = Vector2.ZERO

var grapple_position : Vector2:
	get:
		if is_instance_valid(attached_body):
			return attached_body.to_global(attached_offset)
		return global_position

func wants_grapple():
	if player.seat:
		return false
	return is_grappling

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

func _physics_process(delta: float) -> void:
	if is_multiplayer_authority():
		if will_grapple:
			fire_grapple(mouse_pos)
			will_grapple = false
			is_grappling = true
		
		if not wants_grapple():
			visible = false
			attached_body = null
			is_grappling = false
			sync_grapple.rpc(visible, grapple_position)
			return
			
		visible = true
		set_point_position(0, Vector2.ZERO)
		set_point_position(1, to_local(grapple_position))
		
		sync_grapple.rpc(visible, grapple_position)

		

func _process(_delta: float) -> void:
	var is_local_player = multiplayer.get_unique_id() == player.owner_id
	if is_local_player:
		var grapple = false
		var will_cancel = false
		var mouse = get_global_mouse_position()
		
		if Input.is_action_just_pressed("grapple"):
			grapple = true
		
		if Input.is_action_just_released("grapple"):
			will_cancel = true
		
		if is_multiplayer_authority():
			will_grapple = grapple
			mouse_pos = mouse
			if will_cancel:
				is_grappling = false
		else:
			send_grapple.rpc_id(1, grapple, will_cancel, mouse)
			

@rpc("any_peer", "call_remote", "reliable")
func send_grapple(call_grapple: bool, is_cancelling: bool, m_position: Vector2):
	var sender_id = multiplayer.get_remote_sender_id()
	if sender_id != player.owner_id:
		push_warning("Player %d tried to control player %d" % [sender_id, player.owner_id])
		return
		
	will_grapple = call_grapple
	mouse_pos = m_position
	if is_cancelling:
		is_grappling = false
	
@rpc("authority", "call_remote", "unreliable")
func sync_grapple(is_vis: bool, g_pos: Vector2):
	visible = is_vis
	is_grappling = is_vis
	
	if is_vis:	
		set_point_position(0, Vector2.ZERO)
		set_point_position(1, to_local(g_pos))	

func fire_grapple(mouse_pos):
	var space_state = get_world_2d().direct_space_state
	
	var query = PhysicsPointQueryParameters2D.new()
	query.position = mouse_pos
	query.exclude = [player]
	query.collision_mask = collision_mask
	query.collide_with_areas = true
	query.collide_with_bodies = true
	
	var result = space_state.intersect_point(query)
	if result:
		attached_body = result[0].collider
		attached_offset = attached_body.to_local(mouse_pos)
		is_grappling = true
		
