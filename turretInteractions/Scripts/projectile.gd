class_name Projectile
extends RigidBody2D

@export var damage : float = 10
@export var speed : float = 100

func _ready() -> void:
	linear_velocity = Vector2.from_angle(rotation) * speed
	print("projectile is alive")

func _on_body_entered(body: Node) -> void:
	queue_free()

func _on_lifetime_timeout() -> void:
	queue_free()
