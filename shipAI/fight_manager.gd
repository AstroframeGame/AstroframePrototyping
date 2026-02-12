extends Node

func _ready() -> void:
	pass
	
func _process(delta: float) -> void:
	if get_tree().get_nodes_in_group("enemy_ship").size() < 1:
		print("you won!")
