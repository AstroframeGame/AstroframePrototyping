extends Camera2D

@onready var ship: Ship = get_parent().get_parent()
@export var pos_smooth: float = 10.0
@export var zoom_smooth: float = 10.0
@export var rot_smooth: float = 5.0

var player_zoom := 1.0
var ship_zoom := 0.9
var ship_flight_zoom := 0.5
var ship_flight_offset := Vector2(0, -0.6)

func _ready() -> void:
	global_position = ship.global_position

func _physics_process(delta: float) -> void:
	if not is_instance_valid(ship):
		return

	var target_pos: Vector2
	var zoom_goal: float

	if Input.is_action_pressed("ship_view"):
		target_pos = ship.to_global(ship.center_of_mass)
		zoom_goal = ship_zoom
		ship.ship_mode = ship.SHIP_MODE.EDITING
	else:
		var offset_px = get_viewport_rect().size * ship_flight_offset
		offset_px += Vector2(0, ship.get_bounds_rect().size.y / 2)
		target_pos = ship.to_global(ship.center_of_mass) + offset_px.rotated(ship.global_rotation)
		zoom_goal = ship_flight_zoom
		ship.ship_mode = ship.SHIP_MODE.COMBAT

	global_position = global_position.lerp(target_pos, pos_smooth * delta)
	global_rotation = lerp_angle(global_rotation, ship.global_rotation, rot_smooth * delta)
	var z = lerpf(zoom.x, zoom_goal, zoom_smooth * delta)
	zoom = Vector2(z, z)
