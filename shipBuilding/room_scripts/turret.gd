class_name Turret
extends Room

@onready var gun : Sprite2D = $Gun
var targets_in_range : Array[Ship] = []

func initialize(grid:TileMapLayer) -> void:
	super.initialize(grid)
	find_aim_augment()

func handle_input(event:InputEvent):
	# mouse guided system
	if event.is_action("ship_fire"):
		gun.shoot()
	
	if event is InputEventMouse:
		gun.gunSprite.look_at(get_global_mouse_position())
		
func _on_detection_range_body_entered(body: Node2D) -> void:
	if body is Ship:
		targets_in_range.append(body as Ship)

func _on_detection_range_body_exited(body: Node2D) -> void:
	if body is Ship:
		targets_in_range.erase(body as Ship)

func find_aim_augment()->void:
	for neighbor in ship.find_neighbors(self):
		if neighbor is Aim_Augment:
			if neighbor.target_rooms.size() == 0:
				print("turret paired to augment")
				neighbor.target_rooms.append(self as Turret)
				augments.append(neighbor as Aim_Augment)
