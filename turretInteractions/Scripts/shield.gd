class_name Shield
extends StaticBody2D

@onready var collider = $CollisionShape2D

func set_active(is_active : bool):
	visible = is_active
	collider.disabled = not is_active
