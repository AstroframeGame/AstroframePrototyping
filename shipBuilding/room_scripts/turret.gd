class_name Turret
extends Room

@onready var gun : GunHex = $Gun
@onready var enemy_target : Ship = null
var targets_in_range : Array[Ship] = []

func _process(_delta: float) -> void:
	if enemy_target == null:
		return
	gun.gunSprite.look_at(enemy_target.global_position)
	gun.shoot(10)

func _on_detection_range_body_entered(body: Node2D) -> void:
	# remove soon? we are no longer using exploded ship bits
	if body is Ship and body.get_total_room_count() == 1:
		return
	if not body is Ship or body == ship:
		return
	targets_in_range.append(body as Ship)
	enemy_target = closest_target()

func _on_detection_range_body_exited(body: Node2D) -> void:
	if body is Ship:
		targets_in_range.erase(body as Ship)
		enemy_target = closest_target()


func closest_target()->Ship:
	if targets_in_range.size() == 0:
		return null
	var closest = targets_in_range[0]
	for target in targets_in_range:
		var distance = target.global_position.distance_to(global_position)
		if distance < closest.global_position.distance_to(global_position):
			closest = target
	return closest
