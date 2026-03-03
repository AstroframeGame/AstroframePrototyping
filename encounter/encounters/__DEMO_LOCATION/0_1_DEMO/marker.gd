extends Polygon2D

@export var target: Node2D  # assign point of interest

@onready var label = $Label
@onready var screen_size = get_viewport_rect().size
@onready var center = screen_size / 2
@onready var padding = 75
@onready var y_offset = 4

const FADE_MIN_DIST = 500
const FADE_MAX_DIST = 3000

var cam: Camera2D

func _ready() -> void:
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = Vector2(-label.size.x / 2, y_offset)  
	label.add_theme_color_override("font_color", color)
	
	if target:
		target.tree_exited.connect(queue_free)

func _process(_delta: float) -> void:
	if not target: return
	
	var target_screen_pos = get_viewport().get_canvas_transform() * target.global_position
	
	# if target is on screen, hide the marker
	if Rect2(Vector2.ZERO, screen_size).has_point(target_screen_pos):
		visible = false
		return
	
	visible = true
	
	# get vector pointing from the center of the screen toward the target
	var dir = target_screen_pos - center
	
	# walk from center to screen edge
	var scale_x = (center.x - padding) / abs(dir.x) if dir.x != 0 else INF
	var scale_y = (center.y - padding) / abs(dir.y) if dir.y != 0 else INF
	
	# place marker
	position = (center + dir * min(scale_x, scale_y)).round()
	
	# distance to target
	if not cam:
		cam = get_viewport().get_camera_2d()
	var dist = target.global_position.distance_to(cam.global_position)
	
	# adjust alpha with distance
	var t = remap(dist, FADE_MIN_DIST, FADE_MAX_DIST, 1, 0)
	var dist_mod = smoothstep(0, 1, clamp(t, 0, 1))
	self_modulate.a = dist_mod
	#label.modulate.a = dist_mod

	# add text
	if label.text == "" and target.get_meta("type"):
		label.text = target.get_meta("type")
	
	# keep label centered
	label.pivot_offset = label.size / 2
	label.position = Vector2(-label.size.x / 2, y_offset).round()
