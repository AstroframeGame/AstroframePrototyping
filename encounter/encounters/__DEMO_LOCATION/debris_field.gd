extends Node2D

@export var nav_region: NavigationRegion2D
@onready var field = $moving_field

func _ready() -> void:
	if nav_region:
		print(nav_region.get_bounds())

	# set up movement direction, limits
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
