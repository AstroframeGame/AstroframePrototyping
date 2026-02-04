class_name Projectile
extends RigidBody2D

@export var damage : float = 10
@export var speed : float = 1000

func initialize(parent : Node2D, parent_velocity : Vector2, direction : Vector2):
	global_position = parent.global_position
	global_rotation = parent.global_rotation
	linear_velocity = direction * speed + parent_velocity
	#angular_velocity = # parent? didn't seem to affect anything

func _ready() -> void:
	#linear_velocity = Vector2.from_angle(rotation) * speed
	pass

func _on_body_entered(_body: Node) -> void:
	queue_free()

func _on_lifetime_timeout() -> void:
	queue_free()
