extends Camera2D

'''
Track the camera to the player or ship
'''

var player: PlayerCharacter # set when instantiated by multiplayer manager, this should be set in ready instead
var seat : SeatInteractable :
	get:
		return player.seat
@export var pos_smooth: float = 10.0

@export var zoom_smooth :float = 10.0
var player_zoom = 1.0
var ship_zoom = 0.9
var ship_flight_zoom = 0.5
var ship_flight_offset = Vector2(0,-0.6)

@export var rot_smooth = 5.0

func _ready() -> void:
	var multiplayer_manager : MultiplayerManager = get_parent().get_parent()
	player = multiplayer_manager.my_player
	await get_tree().process_frame
	global_position = player.global_position

func _physics_process(delta: float) -> void:
	var zoom_goal = player_zoom
	if not player:
		return
	if Input.is_action_pressed("ship_view") and player.ship:
		var pos = player.ship.get_piloting().global_position
		global_position = global_position.lerp(pos, pos_smooth * delta)
		global_rotation = lerp_angle(global_rotation, player.ship.global_rotation, rot_smooth * delta)
		zoom_goal = ship_zoom
	elif seat and seat.room is Piloting:
		var offset_px = get_viewport_rect().size * ship_flight_offset
		offset_px += Vector2(0,seat.room.ship.get_bounds_rect().size.y/2)
		var pos = player.ship.get_piloting().global_position + offset_px.rotated(player.ship.global_rotation)
		global_position = global_position.lerp(pos, pos_smooth * delta)
		global_rotation = lerp_angle(global_rotation, player.ship.global_rotation, rot_smooth * delta)
		zoom_goal = ship_flight_zoom
	elif player:
		global_position = global_position.lerp(player.global_position, pos_smooth * delta)
		global_rotation = lerp_angle(global_rotation, player.global_rotation, rot_smooth * delta)
		zoom_goal = player_zoom
		
	var z = lerpf(zoom.x, zoom_goal, zoom_smooth * delta)
	zoom = Vector2(z,z)
