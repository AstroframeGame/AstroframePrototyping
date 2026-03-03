extends Node
class_name MultiplayerManager

var my_player : PlayerCharacter # KEEP THIS
var my_player_system : Node2D
var players : Array[PlayerCharacter]

var peer: SteamMultiplayerPeer
var lobby_id: int = 0
var host_steam_id: int = 0
var is_host: bool = false
var is_joining: bool = false
var user_name: String
var buff_user: String
var curr_scene_path: String
var is_in_scene: bool = false

@onready var game_manager: GameManager = $"../GameManager"
@onready var host: Button = $"../UI/Main/VBoxContainer/Multiplayer/Host"
@onready var join: Button = $"../UI/Main/VBoxContainer/Multiplayer/Join"
@onready var id_prompt: LineEdit = $"../UI/Main/VBoxContainer/Multiplayer/IDPrompt"

const PLAYER_SYSTEM_PREFAB = preload("res://playerMovement/player_system.tscn")
const PLAYER_CHARACTER_PREFAB = preload("res://playerMovement/player_character.tscn")

# Avoid warnings for now
#signal player_join(p : PlayerCharacter)
#signal player_disconnect() # player character might be null? what info is helpful after a player leaves
#signal player_died()

func _ready():
	var is_init = Steam.steamInit(4424670, true)
	print("Steam init: ", is_init)
	Steam.initRelayNetworkAccess()
	user_name = Steam.getPersonaName()
	if is_init:
		print("   Account actualized: ", user_name)
	else:
		print("   Steam failed to Initialize")
	Steam.lobby_created.connect(_on_lobby_created)
	Steam.lobby_joined.connect(_on_lobby_joined)
	
func host_lobby():
	Steam.createLobby(Steam.LobbyType.LOBBY_TYPE_PUBLIC, 16)
	is_host = true
	
func join_lobby(lob_id: int):
	is_joining = true
	Steam.joinLobby(lob_id)

func _on_lobby_created(result: int, lob_id: int):
	if result == Steam.Result.RESULT_OK:
		self.lobby_id = lob_id
		
		peer = SteamMultiplayerPeer.new()
		peer.server_relay = true
		peer.create_host()
		multiplayer.multiplayer_peer = peer
		
		multiplayer.peer_connected.connect(_on_peer_connected)
		multiplayer.peer_disconnected.connect(_on_peer_disconnected)
		
		await get_tree().process_frame
		
		host_steam_id = multiplayer.get_unique_id()
		
		print("\n=== HOST SETUP ===")
		print("   Lobby created, lobby id copied to clipboard: ", lob_id)
		print("   Steam.getSteamID(): ", Steam.getSteamID())
		print("   multiplayer.get_unique_id(): ", multiplayer.get_unique_id())
		print("   Using host_steam_id: ", host_steam_id)
		DisplayServer.clipboard_set(str(lob_id))
		InGameConsole.log_message("   Lobby created, lobby id copied to clipboard: "+ str(lob_id))
		_add_player_local(host_steam_id)

func _on_lobby_joined(lob_id: int, _perms: int, _locked: bool, _response: int):
	if !is_joining:
		return
	
	self.lobby_id = lob_id
	host_steam_id = Steam.getLobbyOwner(lob_id)
	
	peer = SteamMultiplayerPeer.new()
	peer.server_relay = true
	peer.create_client(host_steam_id)
	multiplayer.multiplayer_peer = peer
	
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	
	print("=== CLIENT CONNECTING ===")
	print("   Connecting to host Steam ID: ", host_steam_id)
	print("   My Steam ID (Steam.getSteamID()): ", Steam.getSteamID())
	print("   My peer ID (multiplayer.get_unique_id()): ", multiplayer.get_unique_id())
		
	is_joining = false

func _on_connected_to_server():
	print("\n=== CLIENT CONNECTED ===")
	print("   Successfully connected!")
	print("   Peers visible: ", multiplayer.get_peers())

func _on_connection_failed():
	print("   Connection failed!")

#region OnPeerJoin/Leave
func _on_peer_connected(id):
	print("\n=== PEER_CONNECTED ===")
	print("   My multiplayer ID: ", multiplayer.get_unique_id())
	print("   Peer ID: ", id)
	print("   Is Server: ", multiplayer.is_server())
	
	if is_host:
		_add_player_local(id)

		spawn_player.rpc(id)
		for child in $Players.get_children():
			if child is PlayerCharacter:
				var existing_id = child.name.to_int()
				print("Adding ", id, " to ", existing_id)
				spawn_player.rpc_id(id, existing_id)
				
		if is_in_scene:
			game_manager.load_scenes_across_peers.rpc_id(id, curr_scene_path)
	else:
		$"../UI/Main/ScrollContainer".visible = false
		print("Client: Not spawning (Server owns authority)")

func _on_peer_disconnected(id):
	print("Peer disconnected: ", id)
	_remove_player(id)
	
	if is_host:
		remove_player.rpc(id)

@rpc("any_peer", "call_local", "reliable")
func spawn_player(id: int):
	if not $Players.has_node(str(id)):
		_add_player_local(id)

@rpc("any_peer", "call_local", "reliable")
func remove_player(id: int):
	if not is_host:
		_remove_player(id)
#endregion
#region Adding Player Local
func _add_player_local(id: int):
	if $Players.has_node(str(id)):
		return
	
	var player_char = PLAYER_CHARACTER_PREFAB.instantiate()
	
	player_char.process_mode = Node.PROCESS_MODE_DISABLED
	player_char.name = str(id)
	player_char.set_multiplayer_authority(1)
	$Players.add_child(player_char, true)
	
	var is_owner = id == multiplayer.get_unique_id()
	if is_owner:
		player_char.get_node("NamerTag").text = user_name
		var player_system = PLAYER_SYSTEM_PREFAB.instantiate()
		
		my_player = player_char
		my_player_system = player_system
		
		add_child(player_system, true)
	
	
	print("✓ Spawned player ", id, " authority: ", player_char.get_multiplayer_authority())
	print("Waiting for Host to Enter Game...")

	if multiplayer.get_unique_id() != 1:
		request_scene.rpc_id(1)
	if !is_in_scene:
		var scene = await game_manager.game_start
		print("\nHost Started Game, Loading ", scene.name)
	else:
		print("\nHost is already in the game, loading in...")
	
	if !is_owner:
		request_user.rpc_id(id)
	
	if !is_host:
		await get_tree().process_frame
	
	player_char.process_mode = Node.PROCESS_MODE_ALWAYS

@rpc("any_peer", "call_remote", "reliable")
func request_scene():
	var id = multiplayer.get_remote_sender_id()
	reply_w_scene.rpc_id(id, is_in_scene)
		
@rpc("any_peer", "call_remote", "reliable")
func reply_w_scene(in_scene: bool):
	is_in_scene = in_scene

@rpc("any_peer", "call_remote", "reliable")
func request_user():
	var id = multiplayer.get_remote_sender_id()
	reply_w_user.rpc_id(id, user_name)
	
@rpc("any_peer", "call_remote", "reliable")
func reply_w_user(user: String):
	var id = multiplayer.get_remote_sender_id()
	if $Players.has_node(str(id)):
		print("Setting User of ", id, " to ", user)
		$Players.get_node(str(id)).get_node("NamerTag").text = user


func _remove_player(id: int):
	if !$Players.has_node(str(id)):
		return
	if id == 1:
		game_manager.quit_to_list()
		
	$Players.get_node(str(id)).queue_free()
	print("Removed player ", id)
#endregion
	
func _on_host_pressed() -> void:
	host_lobby()
	
func _on_join_pressed() -> void:
	if is_host:
		return
	join_lobby(id_prompt.text.to_int())

func _on_id_prompt_text_changed(new_text: String) -> void:
	join.disabled = (new_text.length() == 0)

func all_players_dead() -> bool:
	return false
