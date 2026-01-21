extends Ship

signal attack

var event_triggered: bool = false
var player_in_sector: bool = false

func _ready() -> void:
	# TEMP: hardcoding stats for now
	shields = 5
	weapons = 8
	engines = 2
	
	if sector_a:
		sector_a.body_entered.connect(_on_sector_entered.bind(sector_a))
	if sector_b:
		sector_b.body_entered.connect(_on_sector_entered.bind(sector_b))
	
func trigger_event() -> void:
	event_triggered = true
	print("EVENT TRIGGERED: player has warped near npc ship!")
	
	# TEMP: basic combat event
	attack.emit("weapons", 5)

func reset_event() -> void:
	event_triggered = false
