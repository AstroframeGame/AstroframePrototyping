class_name Shield
extends StaticBody2D

signal on_shield_broken()

@onready var collider = $CollisionShape2D

var durability : int

## smooth this later with a coroutine
func set_active(is_active : bool):
	visible = is_active
	collider.disabled = not is_active

func take_damage(amount : int):
	durability -= amount

func _process(_delta: float) -> void:
	if durability < 0:
		set_active(false)
		on_shield_broken.emit()
		durability = 0
