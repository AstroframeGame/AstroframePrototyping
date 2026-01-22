extends Ship

func _ready() -> void:
	name = "player"
	
	# TEMP: hardcoding stats for now
	shields = 9
	weapons = 6
	engines = 8
	
	# attack buttons
	var shields_interact = $Buttons/InteractShields
	var engines_interact = $Buttons/InteractEngines
	var weapons_interact = $Buttons/InteractWeapons
	
	# sloppy hardcoded to attack npc_ship
	shields_interact.pressed.connect(launch_attack.bind(npc_ship, "shields", 2))
	engines_interact.pressed.connect(launch_attack.bind(npc_ship, "engines", 2))
	weapons_interact.pressed.connect(launch_attack.bind(npc_ship, "weapons", 2))
	
	print(npc_ship.shields)
	if npc_ship.shields <= 0: shields_interact.hide()
	if npc_ship.engines <= 0: engines_interact.hide()
	if npc_ship.weapons <= 0: weapons_interact.hide()
	
	# init current_sector
	if sector_a:
		sector_a.body_entered.connect(_on_sector_entered.bind(sector_a))
	if sector_b:
		sector_b.body_entered.connect(_on_sector_entered.bind(sector_b))
		
func _input(event):
	if event is InputEventKey and event.pressed:
		# SPACE to warp
		if event.keycode == KEY_SPACE:
			warp_to_other_sector()

func warp_to_other_sector() -> void:
	if current_sector == sector_a and sector_b:
		# warp to sector B
		global_position = sector_b.global_position + Vector2(randf_range(-5, 5), randf_range(-5, 5))
		print("[PLAYER]: warped to sector B")
	elif current_sector == sector_b and sector_a:
		# warp to sector A
		global_position = sector_a.global_position + Vector2(randf_range(-5, 5), randf_range(-5, 5))
		print("[PLAYER]: warped to sector A")
	else:
		print("[PLAYER]: not in valid sector to warp from", current_sector)
		
	if current_sector == sector_a or current_sector == sector_b:
		var npc_proximity: float = check_proximity(self, npc_ship)
		print("[PLAYER]: npc %.1f away" % npc_proximity)
