class_name Projectile
extends RigidBody2D

@export var damage : int = 10
@export var speed : float = 1000
var owner_ship : Ship

# the owner of the bullet
var firer : Node2D

func initialize(parent : Node2D, parent_velocity : Vector2, projectileSpeed : float, direction : Vector2, spawnPoint : Vector2 = parent.global_position, projectileDamage : int = damage):
	global_position = spawnPoint
	global_rotation = parent.global_rotation
	speed = projectileSpeed
	linear_velocity = direction * speed + parent_velocity
	damage = projectileDamage
	firer = parent
	#angular_velocity = # parent? didn't seem to affect anything

func _on_body_entered(body: Node) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage)
	queue_free()

func _on_lifetime_timeout() -> void:
	queue_free()
