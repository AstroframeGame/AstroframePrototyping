class_name Turret
extends Room
	
@onready var gun : GunHex = $Gun
var targets_in_range : Array[Ship] = []

func _ready() -> void:
	# pair to a nearby aim augment if available
	if ship:
		pair_augments(Aim_Augment)

# THIS SHOULD BE IN THE INPUT SINGLETON
var mouse_controller = "mouse"
func _input(event)-> void:
	if event is InputEventMouseMotion:
		if event.relative.length() > 1:
			mouse_controller = "mouse"
	var look_dir_controller = Input.get_vector("ship_look_left","ship_look_right", "ship_look_down", "ship_look_up")
	if look_dir_controller.length() > 0.1:
		mouse_controller = "controller"

func handle_input(event:InputEvent):
	if not power_level > 0:
		return
	# mouse guided system
	if event.is_action("ship_fire"):
		gun.shoot()
		
	if event is InputEventMouseMotion and mouse_controller == "mouse":
		#_look_at_target_interpolated(gun.gunSprite, 5 * get_process_delta_time())
		gun.gunSprite.look_at(get_global_mouse_position())
	if mouse_controller == "controller":
		var d = Input.get_vector("ship_look_left","ship_look_right", "ship_look_down", "ship_look_up")
		d.x = -1 * d.x
		d = d.rotated(global_rotation)
		gun.gunSprite.rotation = atan2(d.y, d.x)
		
func _on_detection_range_body_entered(body: Node2D) -> void:
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

func closest_target()->Ship:
	var closest = targets_in_range[0]
	for target in targets_in_range:
		var distance = target.global_position.distance_to(global_position)
		if distance < closest.global_position.distance_to(global_position):
			closest = target
	return closest
