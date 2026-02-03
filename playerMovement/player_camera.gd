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
var ship_zoom = 0.5

@export var rot_smooth = 5.0

func _physics_process(delta: float) -> void:
	if seat:
		var ship_offset = Vector2(0,200)
		var pos = player.ship.get_piloting().global_position + ship_offset.rotated(player.ship.global_rotation)
		global_position = global_position.lerp(pos, pos_smooth * delta)
		global_rotation = lerp_angle(global_rotation, player.ship.global_rotation, rot_smooth * delta)
	if player:
		global_position = global_position.lerp(player.global_position, pos_smooth * delta)
		global_rotation = lerp_angle(global_rotation, player.global_rotation, rot_smooth * delta)
		
	var z = lerpf(zoom.x, ship_zoom if seat else player_zoom if player else 1.0, zoom_smooth * delta)
	zoom = Vector2(z,z)
