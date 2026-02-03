extends TestShip

var buttons_box

func _ready() -> void:
	# TEMP: hardcoding stats for now
	var ship_type = get_meta("ship_type", "UNKNOWN")
	
	match ship_type:
		"FACTION":
			shields = 10
			weapons = 10
			engines = 10
		"CIVILIAN":
			shields = 5
			weapons = 0
			engines = 2
		"SCIENCE":
			shields = 8
			weapons = 2
			engines = 10
		"CRIMINAL":
			shields = 10
			weapons = 10
			engines = 10
		_:
			shields = 5
			weapons = 5
			engines = 5
	
	if sector_a:
		sector_a.body_entered.connect(_on_sector_entered.bind(sector_a))
	if sector_b:
		sector_b.body_entered.connect(_on_sector_entered.bind(sector_b))
		
	_set_up_buttons()
	
	# show ship type chosen by user
	var type_label = Label.new()
	type_label.name = "TypeLabel"
	type_label.text = "Type: %s" % get_meta("ship_type", "UNASSIGNED")
	type_label.position = Vector2(-50, -60)  
	add_child(type_label)

func update_type_label():
	if has_node("TypeLabel"):
		$TypeLabel.text = "Type: %s" % get_meta("ship_type", "UNASSIGNED")

# crappy button interaction just for demo purposes
func _set_up_buttons() -> void:
	buttons_box = BoxContainer.new()
	buttons_box.vertical = true
	add_child(buttons_box)
	
	var shields_interact = Button.new()
	shields_interact.name = "shields"
	shields_interact.text = "shields {%d}" % shields
	shields_interact.gui_input.connect(_on_interact.bind("shields", shields_interact))
	buttons_box.add_child(shields_interact)
	
	var weapons_interact = Button.new()
	weapons_interact.name = "weapons"
	weapons_interact.text = "weapons {%d}" % weapons
	weapons_interact.gui_input.connect(_on_interact.bind("weapons",weapons_interact))
	buttons_box.add_child(weapons_interact)
	
	var engines_interact = Button.new()
	engines_interact.name = "engines"
	engines_interact.text = "engines {%d}" % engines
	engines_interact.gui_input.connect(_on_interact.bind("engines", engines_interact))
	buttons_box.add_child(engines_interact)

func _on_interact(event, system: String, button: Button) -> void:
	if event is InputEventMouseButton and event.pressed:
		var ship_type = get_meta("ship_type", "UNKNOWN")
		var interaction_type = ""
		
		if event.button_index == MOUSE_BUTTON_LEFT:
			interaction_type = "damage"
			
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			interaction_type = "repair"
		
		
		# type-specific reactions to interactions
		print("[PLAYER] %ss %s ship's %s..." % [interaction_type, ship_type, system])
		match ship_type:
			"FACTION":
				handle_faction_interaction(system, interaction_type)
			"CIVILIAN":
				handle_civilian_interaction(system, interaction_type)
			"SCIENCE":
				handle_science_interaction(system, interaction_type)
			"CRIMINAL":
				handle_criminal_interaction(system, interaction_type)
			_:
				handle_default_interaction(system, interaction_type)
		
# FACTION SHIP INTERACTIONS
# TODO: relationship bits
func handle_faction_interaction(system: String, interaction_type: String) -> void:
	if interaction_type == "damage":
		match system:
			"shields":
				system_damage("shields", 1) 
				# counter attack
				if player_ship:
					print("[FACTION] returning fire!")
					launch_attack(player_ship, "shields", 2)
					
			"weapons":
				system_damage("weapons", 1)
				# increases defense
				print("[FACTION] increasing shields!")
				system_repair("shields", 1)
				
			"engines":
				system_damage("engines", 2)  
				# counter attack:
				if player_ship:
					print("[FACTION] returning fire!")
					launch_attack(player_ship, "shields", 2)
				
	elif interaction_type == "repair":
		# TODO nuance
		match system:
			"shields":
				system_repair("shields", 1)
				if player_ship:
					print("[FACTION] returning the favor!")
					player_ship.system_repair("shields", 3)
			"weapons":
				system_repair("weapons", 1)
				if player_ship:
					print("[FACTION] returning the favor!")
					player_ship.system_repair("weapons", 3)
			"engines":
				system_repair("engines", 1)
				if player_ship:
					print("[FACTION] returning the favor!")
					player_ship.system_repair("engines", 3)

# CIVILIAN SHIP INTERACTIONS
func handle_civilian_interaction(system: String, interaction_type: String) -> void:
	if interaction_type == "damage":
		match system:
			"shields":
				print("[CIVILIAN] yeeeeowtch!")
				system_damage("shields", 3)  
				if engines > 0:
					print("[CIVILIAN] attempts to flee")
					
			"weapons":
				print("[CIVILIAN] no weapons")
				
			"engines":
				print("[CIVILIAN] engine hit!")
				system_damage("engines", 2)
				# drop cargo when engines are below a threshold
				if engines < 3:
					print("[CIVILIAN] cargo containers ejected")
					print("[CIVILIAN] attempts to flee")
					
				
	elif interaction_type == "repair":
		# TODO nuance
		match system:
			"shields":
				system_repair("shields", 1)
				print("[CIVILIAN] thanks!")
			"weapons":
				print("[CIVILIAN] no weapons here!")
			"engines":
				system_repair("engines", 1)
				print("[CIVILIAN] wow tysm!")

# SCIENCE SHIP INTERACTIONS
func handle_science_interaction(system: String, interaction_type: String) -> void:
	if interaction_type == "damage":
		match system:
			"shields":
				print("[SCIENCE] experimental shields adapting to your weapons!")
				system_damage("shields", 1)
				# science shields regenerate
				await get_tree().create_timer(2.0).timeout
				system_repair("shields", 2)
				print("[SCIENCE] shield regeneration online!")
				
			"weapons":
				print("[SCIENCE] defensive turrets only! we're researchers!")
				system_damage("weapons", 1)
				if player_ship:
					print("[SCIENCE] returning fire!")
					launch_attack(player_ship, "shields", 1)
				
			"engines":
				print("[SCIENCE] engines damaged!")
				system_damage("engines", 2)
				if engines <= 2:
					print("[SCIENCE] emergency jump protocol activated!")
					
	elif interaction_type == "repair":
		# TODO nuance
		match system:
			"shields":
				system_repair("shields", 1)
				if player_ship:
					print("[SCIENCE] returning the favor!")
					player_ship.system_repair("shields", 1)
			"weapons":
				system_repair("weapons", 1)
				if player_ship:
					print("[SCIENCE] wow, thanks!")
					player_ship.system_repair("shields", 2)
			"engines":
				system_repair("engines", 1)
				if player_ship:
					print("[SCIENCE] cool, tysm!")
					player_ship.system_repair("shields", 1)

# CRIMINAL SHIP INTERACTIONS
func handle_criminal_interaction(system: String, interaction_type: String) -> void:
	if interaction_type == "damage":
		match system:
			"shields":
				print("[CRIMINAL] grrr!")
				system_damage("shields", 2)
				if player_ship:
					print("[CRIMINAL] targeting your engines!")
					launch_attack(player_ship, "engines", 3)
					
			"weapons":
				print("[CRIMINAL] weapons hit!")
				system_damage("weapons", 2)
				if player_ship and engines > 3:
					launch_attack(player_ship, "shields", 4)
					
			"engines":
				print("[CRIMINAL] engine hit!")
				system_damage("engines", 2)
				if engines <= 2:
					print("[CRIMINAL] jettisoning cargo!")
					
	elif interaction_type == "repair":
		match system:
			"shields":
				system_repair("shields", 1)
			"weapons":
				system_repair("weapons", 1)
			"engines":
				system_repair("engines", 1)

# DEFAULT/UNKNOWN INTERACTIONS
func handle_default_interaction(system: String, interaction_type: String) -> void:
	if interaction_type == "damage":
		print("[UNKNOWN] System taking damage!")
		system_damage(system, 2)
	elif interaction_type == "repair":
		print("[UNKNOWN] System scanned - no special properties detected")

# called when another ship enters this ship's sector
func sector_entered(body: TestShip) -> void:
	var my_ship_type = get_meta("ship_type", "UNKNOWN")
	var location_type = current_sector.get_meta("location_type", "UNKNOWN")
	
	#print("[%s]: %s ship in %s location" % [name.to_upper(), my_ship_type, location_type])
	
	# get event info from global data
	var event_id = EncounterData.get_event_id(location_type, my_ship_type)
	var description = EncounterData.get_encounter_description(location_type, my_ship_type)
	
	#print("[%s]: event ID %d - %s" % [name.to_upper(), event_id, description])

func get_encounter_info() -> Dictionary:
	var ship_type = get_meta("ship_type", "")
	var location_type = current_sector.get_meta("location_type", "") if current_sector else ""
	
	if ship_type == "" or location_type == "":
		return {}
	
	# TODO: MAKE GLOBAL
	var ship_types = {"FACTION": 1, "CIVILIAN": 2, "SCIENCE": 3, "CRIMINAL": 4}
	var locations = {"ASTRO_OBJ": 1, "STRUCTURE": 2, "SPACE_STATION": 3, "MILITARY_BASE": 4, "BATTLEFIELD": 5, "VOID": 6}
	
	var location_val = locations.get(location_type, 0)
	var ship_val = ship_types.get(ship_type, 0)
	var event_id = location_val * 10 + ship_val
	
	return {
		"event_id": event_id,
		"location_type": location_type,
		"ship_type": ship_type
	}
	
func update_label(name: String):
	if(buttons_box.get_node(name)):
		buttons_box.get_node(name).text = "%s {%d}" % [name, self[name]]
	else:
		print("[PLAYER][ERROR]: \"%s\" not found" % name)
