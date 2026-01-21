extends Node2D

@export var sector_a: Area2D
@export var sector_b: Area2D
@export var npc_ship: Area2D
@export var player_ship: CharacterBody2D

func _ready() -> void:
	# npc ship signal
	if npc_ship:
		npc_ship.player_nearby.connect(_on_npc_event_triggered)
	
	# sectors signals
	if sector_a:
		sector_a.body_entered.connect(_on_sector_a_entered)
	if sector_b:
		sector_b.body_entered.connect(_on_sector_b_entered)

func _on_sector_a_entered(body: Node2D) -> void:
	if body == player_ship:
		print("player entered sector A")

func _on_sector_b_entered(body: Node2D) -> void:
	if body == player_ship:
		print("player entered sector B")
		check_npc_proximity() # looks for an npc nearby

func check_npc_proximity() -> void:
	if not npc_ship or not player_ship:
		return
	
	# TODO: check ship types ?

func _on_npc_event_triggered() -> void:
	print("npc event triggered")
	# do something
