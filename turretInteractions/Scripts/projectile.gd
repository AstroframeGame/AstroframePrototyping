class_name Projectile
extends RigidBody2D

@export var damage : float = 10
@export var speed : float = 200

func initialize(parent : Node2D, parent_velocity : Vector2, direction : Vector2, spawnPoint : Vector2 = parent.global_position):
	global_position = spawnPoint
	global_rotation = parent.global_rotation
	linear_velocity = direction * speed + parent_velocity

func _ready() -> void:
	#linear_velocity = Vector2.from_angle(rotation) * speed
	pass

func _on_body_entered(_body: Node) -> void:
	queue_free()

func _on_lifetime_timeout() -> void:
	queue_free()
