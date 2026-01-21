extends Node2D

@export var sector_a: Area2D
@export var sector_b: Area2D
@export var npc_ship: Ship
@export var player_ship: Ship

func _ready() -> void:
	# sectors signals
	if sector_a:
		sector_a.body_entered.connect(_on_sector_a_entered)
	if sector_b:
		sector_b.body_entered.connect(_on_sector_b_entered)

func _on_sector_a_entered(body: Node2D) -> void:
	if body == player_ship:
		print("[INFO] player entered sector A")

func _on_sector_b_entered(body: Node2D) -> void:
	if body == player_ship:
		print("[INFO] player entered sector B")
