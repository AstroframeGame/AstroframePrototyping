class_name Turret
extends Room

@onready var gun : GunHex = $Gun
var targets_in_range : Array[Ship] = []
var controlled_by: PlayerCharacter

var turret_damage: int = 10

func _ready() -> void:
	super._ready()
	# pair to a nearby aim augment if available
	if ship:
		pair_augments(Aim_Augment)

func handle_input(event: StringName):
	if not controlled_by:
		return
	if controlled_by.is_local_player:
		print("Power Level: ", power_level)
		if not power_level > 0:
			return
		# mouse guided system
		if event == "ship_fire":
			if is_multiplayer_authority():
				gun.shoot(turret_damage)
				sync_shot.rpc(turret_damage)
			else:
				send_shot.rpc_id(1)

@rpc("any_peer", "call_remote", "reliable")
func send_shot():
	var sender_id = multiplayer.get_remote_sender_id()
	var ctrl_id = controlled_by.owner_id
	if sender_id != ctrl_id:
		push_warning("[turret.gd]: Player %d tried to control player %d" % [sender_id, ctrl_id])
		return
	gun.shoot(turret_damage)
	sync_shot.rpc(turret_damage)

@rpc("authority", "call_remote", "unreliable")
func sync_shot(dmg: int):
	if not is_multiplayer_authority():
		gun.shoot(dmg)

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

#region MultiplayerProcessing

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if not controlled_by:
		return
	if not power_level > 0:
		return
		
	if is_multiplayer_authority():
		pass # keeping standard structure
	else:
		pass
	gun.gunSprite.look_at(controlled_by.mouse_pos)
	return # temporary, controller needs to be synced
	@warning_ignore("unreachable_code")
	if InputHelper.using_mouse:
		gun.gunSprite.look_at(controlled_by.mouse_pos)
	else:
		var d = InputHelper.controller_look
		d = d.rotated(global_rotation)
		gun.gunSprite.rotation = atan2(d.y, d.x)

func _process(_delta: float) -> void:
	if not controlled_by:
		return
	if controlled_by.is_local_player:
		pass

#endregion

#region PlayerGetUp/Sit
func player_sit_interact(player: PlayerCharacter):
	controlled_by = player
	print("[turret.gd]: Player sat on turret seat")

func player_getup_interact():
	controlled_by = null
	print("[turret.gd]: Player got up from turret seat")
#endregion
