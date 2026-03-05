extends AudioListener2D

var player
func _ready() -> void:
	MusicManager.set_tense_mode(false)
	var multiplayer_manager : MultiplayerManager = $"../../.."
	player = multiplayer_manager.my_player
	var check : Area2D = player.get_node("EnemyCheck")
	check.body_entered.connect(update_tensity)
	check.body_exited.connect(update_tensity)
	await get_tree().process_frame
	update_tensity()

func update_tensity(_body=null):
	var check : Area2D = player.get_node("EnemyCheck")
	for b in check.get_overlapping_bodies():
		if b is Ship:
			if true: # if ship is evil
				MusicManager.set_tense_mode(true)
				return
	
	MusicManager.set_tense_mode(false)
