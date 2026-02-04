class_name Projectile
extends RigidBody2D

@export var damage : float = 0
@export var speed : float = 200

func initialize(parent : Node2D, parent_velocity : Vector2, projectileSpeed : float, direction : Vector2, spawnPoint : Vector2 = parent.global_position, projectileDamage : int = damage):
	global_position = spawnPoint
	global_rotation = parent.global_rotation
	speed = projectileSpeed
	linear_velocity = direction * speed + parent_velocity
	damage = projectileDamage

func _ready() -> void:
	#linear_velocity = Vector2.from_angle(rotation) * speed
	pass

func _on_body_entered(body: Node) -> void:
	if body.has_method("takeDamage"):
		body.takeDamage(damage)
	queue_free()

func _on_lifetime_timeout() -> void:
	queue_free()
