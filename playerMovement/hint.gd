extends Label

var player: PlayerCharacter
func _ready() -> void:
	var multiplayer_manager : MultiplayerManager = get_parent().get_parent().get_parent()
	player = multiplayer_manager.my_player
	await get_tree().process_frame

func _process(_delta: float) -> void:
	update_hint()

func update_hint():
	var actions : Array[String] = []
	if player.ground_body != null and player.ground_body is Ship and player.ship == null and not player.pushing:
		var place_hint = "["+ InputHelper.get_key_mapping("detach") + "] "+ " Detatch Room"
		actions.append(place_hint)
	if player.ground_body != null and player.ground_body is Ship and player.ship == null and player.pushing:
		var place_hint = "["+ InputHelper.get_key_mapping("detach") + "] "+ " Let go of Room"
		actions.append(place_hint)
	if  player.ground_body != null and player.ground_body is Ship and player.ship == null and player.pushing:
		var place_hint = "["+ InputHelper.get_key_mapping("interact") + "] "+ "Place Room"
		actions.append(place_hint)
	var i_hint = player.get_interactable_hint()
	if i_hint != "":
		actions.append("["+ InputHelper.get_key_mapping("interact") + "] "+ i_hint)
	var hint : String = "\n".join(actions)
	text = hint
