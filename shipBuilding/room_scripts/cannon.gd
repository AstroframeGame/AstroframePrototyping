class_name Cannon
extends Room

@onready var gun : GunHex = $GunHex
@onready var multiplayer_manager : MultiplayerManager = get_tree().root.get_node("Hub/MultiplayerManager")
@export var damage = 20

func shoot():
	if is_multiplayer_authority():
		var is_local_player = multiplayer.get_unique_id() == multiplayer_manager.my_player.owner_id
		if power_level > 0:
			gun.shoot(damage)
		elif is_local_player:
			blink_red()
		sync_shooting.rpc()

@rpc("authority", "call_remote", "reliable")
func sync_shooting():
	if power_level > 0:
		gun.shoot(damage)
	else:
		blink_red()
