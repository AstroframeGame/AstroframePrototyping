extends Node
class_name MultiplayerManager

@onready var game_manager: GameManager = $"../GameManager"

const PLAYER_SYSTEM_PREFAB = preload("res://playerMovement/player_system.tscn")
const PLAYER_CHARACTER_PREFAB = preload("res://playerMovement/player_character.tscn")

var players : Array[PlayerCharacter]
var my_player : PlayerCharacter # maybe change to property
var my_player_system : Node2D

func _ready() -> void:
	game_manager.game_start.connect(create_player)
	game_manager.game_quit.connect(remove_my_player)
	game_manager.game_quit.connect(clear_projectiles)

func create_player(_world):
	# if player is multiplayer authority
	my_player_system = PLAYER_SYSTEM_PREFAB.instantiate()
	my_player = PLAYER_CHARACTER_PREFAB.instantiate()
	call_deferred("add_child", my_player_system)
	call_deferred("add_child", my_player)

func remove_my_player():
	if my_player_system:
		my_player_system.call_deferred("queue_free")
	if my_player:
		my_player.call_deferred("queue_free")

@onready var projectiles: Node2D = $Projectiles
func clear_projectiles():
	for p in projectiles.get_children():
		p.call_deferred("queue_free")
