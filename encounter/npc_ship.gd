extends Ship

func _ready() -> void:
	name = "aggro"
	
	# TEMP: hardcoding stats for now
	shields = 5
	weapons = 8
	engines = 2
	
	if sector_a:
		sector_a.body_entered.connect(_on_sector_entered.bind(sector_a))
	if sector_b:
		sector_b.body_entered.connect(_on_sector_entered.bind(sector_b))
		
	_set_up_buttons()

# crappy button interaction just for demo purposes
func _set_up_buttons() -> void:
	var buttons_box = BoxContainer.new()
	buttons_box.vertical = true
	add_child(buttons_box)
	
	var shields_interact = Button.new()
	shields_interact.text = "shields"
	shields_interact.gui_input.connect(_on_interact.bind("shields"))
	buttons_box.add_child(shields_interact)
	
	var weapons_interact = Button.new()
	weapons_interact.text = "weapons"
	weapons_interact.gui_input.connect(_on_interact.bind("weapons"))
	buttons_box.add_child(weapons_interact)
	
	var engines_interact = Button.new()
	engines_interact.text = "engines"
	engines_interact.gui_input.connect(_on_interact.bind("engines"))
	buttons_box.add_child(engines_interact)

# damage or repair systems
func _on_interact(event, type) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			system_damage(type, 1)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			system_repair(type, 1)

# this NPC will attack any ship that enters its sector
func sector_entered(body: Ship) -> void:
	print("[%s]: EVENT TRIGGERED: %s has warped near %s!" % 
		[self.name.to_upper(), body.name, self.name])

	trigger_event("attack", body)

func trigger_event(type: String, body: Ship) -> void:
	if type == "attack":
		# TEMP: basic combat event
		launch_attack(body, "engines", 2)
