extends Camera2D

'''
Track the camera to the player or ship
'''

@onready var player: Player = $"../Player"
var seat : SeatInteractable :
	get:
		return player.seat
@export var pos_smooth: float = 10.0

@export var zoom_smooth :float = 10.0
var player_zoom = 1.0
var ship_zoom = 0.9
var ship_flight_zoom = 0.5
var ship_flight_offset = Vector2(0,-500)

@export var rot_smooth = 5.0

func _physics_process(delta: float) -> void:
	var zoom_goal = player_zoom
	if Input.is_action_pressed("ship_view") and player.ship:
		var pos = player.ship.get_piloting().global_position
		global_position = global_position.lerp(pos, pos_smooth * delta)
		global_rotation = lerp_angle(global_rotation, player.ship.global_rotation, rot_smooth * delta)
		zoom_goal = ship_zoom
	elif seat and seat.room is Piloting:
		var pos = player.ship.get_piloting().global_position + ship_flight_offset.rotated(player.ship.global_rotation)
		global_position = global_position.lerp(pos, pos_smooth * delta)
		global_rotation = lerp_angle(global_rotation, player.ship.global_rotation, rot_smooth * delta)
		zoom_goal = ship_flight_zoom
	elif player:
		global_position = global_position.lerp(player.global_position, pos_smooth * delta)
		global_rotation = lerp_angle(global_rotation, player.global_rotation, rot_smooth * delta)
		zoom_goal = player_zoom
		
	var z = lerpf(zoom.x, zoom_goal, zoom_smooth * delta)
	zoom = Vector2(z,z)
