class_name Turret
extends Room
	
@onready var gun : GunHex = $Gun
var targets_in_range : Array[Ship] = []

func _ready() -> void:
	super._ready()
	# pair to a nearby aim augment if available
	if ship:
		pair_augments(Aim_Augment)

func handle_input(event:InputEvent):
	if not power_level > 0:
		blink_red()
		return
	# mouse guided system
	if event.is_action_pressed("ship_fire"):
		gun.shoot(10)
		
	if InputHelper.using_mouse:
		gun.gunSprite.look_at(get_global_mouse_position())
	else:
		var d = InputHelper.controller_look
		if d.length() > 0.5:
			gun.gunSprite.rotation = atan2(-d.y, -d.x) + deg_to_rad(30) + global_rotation
		
func _on_detection_range_body_entered(body: Node2D) -> void:
	if body is Ship and body.get_total_room_count() == 1:
		return
	if not body is Ship or body == ship:
		return
	var aim_aug = augment_in_list(Aim_Augment)
	if aim_aug == -1 or augments[aim_aug].enemy_target:
		return
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
		else:
			augments[aim_aug].enemy_target = null

func closest_target()->Ship:
	var closest = targets_in_range[0]
	for target in targets_in_range:
		var distance = target.global_position.distance_to(global_position)
		if distance < closest.global_position.distance_to(global_position):
			closest = target
	return closest
