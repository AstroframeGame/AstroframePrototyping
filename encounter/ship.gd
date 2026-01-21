extends CharacterBody2D
class_name Ship

@export var sector_a: Area2D
@export var sector_b: Area2D
@export var npc_ship: Ship
@export var player_ship: Ship

var current_sector: Area2D = null

# systems
var shields: int
var engines: int
var weapons: int

func _ready() -> void:
	pass	

func check_proximity(shipA: Ship, shipB: Ship) -> float:
	if not shipA or not shipB:
		return -1
	
	return shipA.global_position.distance_to(shipB.global_position)

func _on_sector_entered(body: Node2D, sector: Area2D) -> void:
	if body == self:
		current_sector = sector
