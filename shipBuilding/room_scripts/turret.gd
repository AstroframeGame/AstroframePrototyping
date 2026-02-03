class_name Turret
extends Room

'''
fog of war:
    1) multiple turrets (A* & B*) on board
        a) Do turrets share vision? EX: A* has a enemy in range 
           but no augment. B* does. So does B* lock onto A*'s 
           target? 
           perks: good single target damage but no wave clear 
           can hide some turrets and have some more exposed as 
           ones act as "scouts"
        b) Turrets' vision is independent
           perks: multi targetting, need to group turrets for good
		   single target dmg output, needs better ship movement
		c) both? let players switch between the two modes   
'''
	
@onready var gun : Sprite2D = $Gun
var targets_in_range : Array[Ship] = []

func initialize(grid:TileMapLayer) -> void:
	super.initialize(grid)
	# pair to a nearby aim augment if available
	for neighbor in ship.find_neighbors(self):
		if neighbor is Aim_Augment:
			if neighbor.target_rooms.size() == 0:
				#print("turret paired to augment")
				neighbor.target_rooms.append(self as Turret)
				augments.append(neighbor as Aim_Augment)

func handle_input(event:InputEvent):
	# mouse guided system
	if event.is_action("ship_fire"):
		gun.shoot()
	
	if event is InputEventMouseMotion:
		#_look_at_target_interpolated(gun.gunSprite, 5 * get_process_delta_time())
		gun.gunSprite.look_at(get_global_mouse_position())
		
func _on_detection_range_body_entered(body: Node2D) -> void:
	if not body is Ship or body == ship:
		return
	var aim_aug = augment_in_list(Aim_Augment)
	if aim_aug == -1 or augments[aim_aug].enemy_target:
		return
	print("aim_augment found target")
	augments[aim_aug].enemy_target = body
	targets_in_range.append(body as Ship)

func _on_detection_range_body_exited(body: Node2D) -> void:
	if body is Ship:
		targets_in_range.erase(body as Ship)
		
	var aim_aug = augment_in_list(Aim_Augment)
	if aim_aug == -1:
		return
	
	if body == augments[aim_aug].enemy_target:
		if targets_in_range.size() > 0:
			augments[aim_aug].enemy_target = closest_target()

func closest_target()->Ship:
	var closest = targets_in_range[0]
	for target in targets_in_range:
		var distance = target.global_position.distance_to(global_position)
		if distance < closest.global_position.distance_to(global_position):
			closest = target
	return closest
