extends Polygon2D

@export var target: Node2D  # assign point of interest

@onready var screen_size = get_viewport_rect().size
@onready var center = screen_size / 2

func _process(_delta: float) -> void:
	if not target: return
	
	var screen_pos = get_viewport().get_canvas_transform() * target.global_position
	
	# if target is on screen, hide the marker
	if Rect2(Vector2.ZERO, screen_size).has_point(screen_pos):
		visible = false
		return
	
	visible = true
	
	# get vector pointing from the center of the screen toward the target
	var dir = screen_pos - center
	
	# walk from center to screen edge
	var scale_x = (center.x - 20) / abs(dir.x) if dir.x != 0 else INF
	var scale_y = (center.y - 20) / abs(dir.y) if dir.y != 0 else INF
	
	# place marker
	position = center + dir * min(scale_x, scale_y)
