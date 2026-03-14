extends Encounter

func _ready() -> void:	
	LevelStateManager.current_scene_path = "res://encounter/encounters/0_INIT_HOME/0_INTRO/0_INTRO.tscn"
	
	# hardcode warp destination to start
	if not LevelStateManager.warp_scene_path:
		LevelStateManager.warp_scene_path = "res://encounter/encounters/__DEMO_LOCATION/0_1_DEMO/0_1_DEMO.tscn"
	
	player_ship = $PlayerShip
	player_ship.set_meta("type", "PlayerShip")

	player_spawn = $PlayerSpawn.global_position
