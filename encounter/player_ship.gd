extends CharacterBody2D

@export var sector_a: Area2D
@export var sector_b: Area2D
@export var npc_ship: Area2D

var current_sector: Area2D = null

func _ready() -> void:
	if sector_a:
		sector_a.body_entered.connect(_on_sector_entered.bind(sector_a))
	if sector_b:
		sector_b.body_entered.connect(_on_sector_entered.bind(sector_b))
		
func _process(_delta: float) -> void:
	# press space to warp
	if Input.is_action_just_pressed("ui_accept"):
		warp_to_other_sector()

func warp_to_other_sector() -> void:
	if current_sector == sector_a and sector_b:
		# warp to sector B
		# TEMP: forcing to warp near npc ship for now
		global_position = npc_ship.global_position + Vector2(randf_range(-5, 5), randf_range(-5, 5))
		print("warped to sector B")
	elif current_sector == sector_b and sector_a:
		# warp to sector A
		global_position = sector_a.global_position + Vector2(randf_range(-5, 5), randf_range(-5, 5))
		print("warped to sector A")
	else:
		print("not in valid sector to warp from")

func _on_sector_entered(body: Node2D, sector: Area2D) -> void:
	if body == self:
		current_sector = sector
