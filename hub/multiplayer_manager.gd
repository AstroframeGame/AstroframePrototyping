extends Node
class_name MultiplayerManager

@onready var game_manager: GameManager = $"../GameManager"

const PLAYER_SYSTEM_PREFAB = preload("res://playerMovement/player_system.tscn")
const PLAYER_CHARACTER_PREFAB = preload("res://playerMovement/player_character.tscn")

var players : Array[PlayerCharacter]
var my_player : PlayerCharacter # KEEP THIS
var my_player_system : Node2D

signal player_join(p : PlayerCharacter)
signal player_disconnect() # player character might be null? what info is helpful after a player leaves
signal player_died()

func all_players_dead() -> bool:
	return false

# by wednesday, lets get player movement at minimum
# by friday lets get players, ships, projectiles synced

func _ready() -> void:
	game_manager.game_start.connect(create_player)
	game_manager.game_quit.connect(remove_my_player)
	game_manager.game_quit.connect(ProjectileManager.clear) # good

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

# handle all multiplayer things
