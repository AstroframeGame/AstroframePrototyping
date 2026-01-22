extends Sprite2D

@onready var text_prompt : Label = $"Sit Prompt"
@onready var pc = get_tree().get_first_node_in_group("player_controller")
var player_in_area : bool
var has_seated_player : bool

func _ready() -> void:
	text_prompt.hide()
	player_in_area = false
	has_seated_player = false
	
func _on_trigger_collider_area_shape_entered(area_rid: RID, area: Area2D, area_shape_index: int, local_shape_index: int) -> void:
	if area.get_parent() is CharacterBody2D:
		player_in_area = true
		text_prompt.show()

func _on_trigger_collider_area_shape_exited(area_rid: RID, area: Area2D, area_shape_index: int, local_shape_index: int) -> void:
	if area.get_parent() is CharacterBody2D:
		player_in_area = false
		has_seated_player = false
		text_prompt.hide()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		if player_in_area:
			# sit up
			if has_seated_player:
				has_seated_player = false
				pc.can_move = true
				print("player sat up")
			# sit down
			else:
				has_seated_player = true
				pc.can_move = false
				pc.global_position = global_position
				print("player sat down")
		
		
