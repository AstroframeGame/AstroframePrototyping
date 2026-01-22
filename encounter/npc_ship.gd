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
		
# this NPC will attack any ship that enters its sector
func sector_entered(body: Ship) -> void:
	print("[%s]: EVENT TRIGGERED: %s has warped near %s!" % 
		[self.name.to_upper(), body.name, self.name])

	trigger_event("attack", body)

func trigger_event(type: String, body: Ship) -> void:
	if type == "attack":
		# TEMP: basic combat event
		launch_attack(body, "engines", 2)
