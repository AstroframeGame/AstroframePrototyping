extends TestShip

var label_box

func _ready() -> void:
	name = "player"
	state = State.new()
	
	# TEMP: hardcoding stats for now
	shields = 9
	weapons = 6
	engines = 8
	
	# init current_sector
	if sector_a:
		sector_a.body_entered.connect(_on_sector_entered.bind(sector_a))
	if sector_b:
		sector_b.body_entered.connect(_on_sector_entered.bind(sector_b))
		
	# show systems stats
	label_box = BoxContainer.new()
	label_box.vertical = true
	label_box.position = Vector2(-40, 50)  
	add_child(label_box)
	setup_labels()

func setup_labels():
	var shields_label = Label.new()
	shields_label.name = "shields"
	shields_label.text = "shields {%d}" % self.shields
	label_box.add_child(shields_label)
	
	var weapons_label = Label.new()
	weapons_label.name = "weapons"
	weapons_label.text = "weapons {%d}" % self.weapons
	label_box.add_child(weapons_label)
	
	var engines_label = Label.new()
	engines_label.name = "engines"
	engines_label.text = "engines {%d}" % self.engines
	label_box.add_child(engines_label)


func update_label(name: String):
	if(label_box.get_node(name)):
		label_box.get_node(name).text = "%s {%d}" % [name, self[name]]
	else:
		print("[PLAYER][ERROR]: \"%s\" not found" % name)
		
func _input(event):
	if event is InputEventKey and event.pressed:
		# SPACE to warp
		if event.keycode == KEY_SPACE:
			warp_to_other_sector()

func warp_to_other_sector() -> void:
	if current_sector == sector_a and sector_b:
		# warp to sector B
		global_position = sector_b.global_position + Vector2(randf_range(-5, 5), randf_range(-5, 5))
		#print("[PLAYER]: warped to sector B")
	elif current_sector == sector_b and sector_a:
		# warp to sector A
		global_position = sector_a.global_position + Vector2(randf_range(-5, 5), randf_range(-5, 5))
		#print("[PLAYER]: warped to sector A")
	else:
		print("[PLAYER]: not in valid sector to warp from", current_sector)
		
	if current_sector == sector_a or current_sector == sector_b:
		var npc_proximity: float = check_proximity(self, npc_ship)
		#print("[PLAYER]: npc %.1f away" % npc_proximity)
