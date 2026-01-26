extends Camera2D

'''
Track the camera to the player or ship
'''

@onready var player: CharacterBody2D = $"../Player"
@export var smooth_speed: float = 10.0

func _physics_process(delta: float) -> void:
	if player:
		global_position = global_position.lerp(player.global_position, smooth_speed * delta)
