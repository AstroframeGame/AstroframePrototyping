extends Area2D

signal player_nearby

var event_triggered: bool = false
var player_in_sector: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player ship":
		player_in_sector = true
		trigger_event()

func _on_body_exited(body: Node2D) -> void:
	if body.name == "Player ship":
		player_in_sector = false

func trigger_event() -> void:
	event_triggered = true
	player_nearby.emit()
	print("EVENT TRIGGERED: player has warped near npc ship!")
	
	# TODO: event logic here

func reset_event() -> void:
	event_triggered = false
