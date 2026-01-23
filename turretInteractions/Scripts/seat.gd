extends Sprite2D

@onready var text_prompt : Label = $"Sit Prompt"
@onready var pc = get_tree().get_first_node_in_group("player_controller")
var player_in_area : bool
var player_in_seat : bool
signal seat_unhandled_input(event:InputEvent)

func _ready() -> void:
	text_prompt.hide()
	player_in_area = false
	player_in_seat = false
	
	
func _on_trigger_collider_area_shape_entered(_area_rid: RID, area: Area2D, _area_shape_index: int, _local_shape_index: int) -> void:
	if area.get_parent() is CharacterBody2D:
		player_in_area = true
		text_prompt.show()

func _on_trigger_collider_area_shape_exited(_area_rid: RID, area: Area2D, _area_shape_index: int, _local_shape_index: int) -> void:
	if area.get_parent() is CharacterBody2D:
		player_in_area = false
		player_in_seat = false
		text_prompt.hide()

func _unhandled_input(event: InputEvent) -> void:
	if player_in_area:
		if player_in_seat:
			seat_unhandled_input.emit(event)
		
		if event.is_action_pressed("interact"):
			# sit up
			if player_in_seat:
				player_in_seat = false
				pc.can_move = true
			# sit down
			else:
				player_in_seat = true
				pc.can_move = false
				text_prompt.hide()
				pc.global_position = global_position
