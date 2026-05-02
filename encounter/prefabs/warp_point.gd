extends Area2D
class_name WarpPoint

# var hold the place this warps too.
# LevelStateManager? or a new Autoload for map state, warp destinatios (prob indexes)

# in ship h

func _on_body_entered(body: Node2D) -> void:
	pass # Replace with function body.
	if body is Ship: # and player is ship
		pass
		# open MenuManager.open_menu("Map")
		# start next level
