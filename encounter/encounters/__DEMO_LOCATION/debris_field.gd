extends Node2D

@export var nav_region: NavigationRegion2D

@onready var spawn_path = $spawn_path
@onready var field = $moving_field
@onready var screen_size = get_viewport_rect().size
@onready var center = screen_size / 2

func _ready() -> void:
	# set up movement direction and limits for asteroids
	for asteroid in field.get_children():
		asteroid.start_pos = asteroid.global_position
		asteroid.velocity = Vector2(
			randf_range(0.008, 0.025),
			randf_range(0.001, 0.03)
		)
		asteroid.movement_radius = Vector2(
			randf_range(0.5, 5),
			randf_range(0.5, 5)
		)
		asteroid.start_rot = asteroid.rotation
		asteroid.rotation_velocity = randf_range(0.0001, 0.0002)
		asteroid.rotation_limit = randf_range(0.1, 1)

func _process(_delta: float) -> void:
	if not field: return
	
	# idle movement
	for asteroid in field.get_children():
		var screen_pos = get_viewport().get_canvas_transform() * asteroid.global_position
		
		# do not move if not on sceen
		if not Rect2(Vector2.ZERO, screen_size).has_point(screen_pos):
			continue
		
		asteroid.global_position += asteroid.velocity
		if(
			(asteroid.global_position.x > asteroid.start_pos.x + asteroid.movement_radius.x) or
			(asteroid.global_position.x < asteroid.start_pos.x - asteroid.movement_radius.x)
		):
			asteroid.velocity = -asteroid.velocity
		
		asteroid.rotation += asteroid.rotation_velocity
		if(
			(asteroid.rotation > asteroid.start_rot + asteroid.rotation_limit) or
			(asteroid.rotation < asteroid.start_rot - asteroid.rotation_limit)
		):
			asteroid.rotation_velocity = -asteroid.rotation_velocity
