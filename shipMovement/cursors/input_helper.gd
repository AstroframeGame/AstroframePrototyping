extends Node2D

#TODO: SYNC CONTROLLER INPUT

@onready var multiplayer_manager: MultiplayerManager = get_tree().root.get_node("Hub/MultiplayerManager")
var my_player: PlayerCharacter

signal switch_input_device()
var _using_mouse : bool = true
var using_mouse: bool :
	get:
		return _using_mouse
	set(value):
		if _using_mouse != value:
			_using_mouse = value
			_update_cursor_visibility()
			switch_input_device.emit()

var move : Vector2:
	get:
		return Input.get_vector("left", "right", "up", "down")

var look : Vector2:
	get:
		return _look_delta

var controller_look : Vector2:
	get:
		return Input.get_vector("ship_look_left", "ship_look_right", "ship_look_up", "ship_look_down")

var mouse_center_offset : Vector2:
	get:
		var center = get_viewport().get_visible_rect().get_center()
		return get_viewport().get_mouse_position() - center

func get_look_position(player : PlayerCharacter, distance : float) -> Vector2:
	if using_mouse:
		return player.mouse_pos
	else:
		var pos = player.global_transform.get_origin()
		var dir = look.rotated(player.global_transform.get_rotation())
		var target_pos = pos + dir * distance 
		
		var space_state = get_viewport().get_world_2d().direct_space_state
		var query = PhysicsRayQueryParameters2D.create(pos, target_pos, player.ground_check.collision_mask)
		
		query.exclude = [player.get_rid()] 

		var result = space_state.intersect_ray(query)
		
		if result:
			return result.position
		return target_pos

func mouse_center_offset_deadzone(player: PlayerCharacter, percent : float = 0.05) -> Vector2:
	var look_dir = player.screen_mouse_pos
	var screen_width = get_viewport().get_visible_rect().size.x
	var deadzone_px = screen_width * percent
	
	if abs(look_dir.x) < deadzone_px:
		look_dir.x = 0
	else:
		look_dir.x -= deadzone_px * sign(look_dir.x) 
	
	return look_dir

var _look_delta: Vector2 = Vector2.ZERO

func _ready() -> void:
	_update_cursor_visibility()
	await get_tree().process_frame
	if multiplayer_manager:
		my_player = multiplayer_manager.my_player

func _input(event: InputEvent) -> void:
	
	if event is InputEventMouseMotion:
		using_mouse = true
		_look_delta = event.relative
	elif event is InputEventMouseButton:
		using_mouse = true
	elif event is InputEventJoypadButton or event is InputEventJoypadMotion:
		if event is InputEventJoypadMotion and abs(event.axis_value) < 0.2:
			return
		using_mouse = false

func _process(_delta: float) -> void:
	if not using_mouse:
		_look_delta = controller_look
	elif not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_look_delta = Vector2.ZERO # delta needs to be reset every frame

func _update_cursor_visibility() -> void:
	if using_mouse:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN

func get_key_mapping(input_name : StringName) -> String:
	var event_index = 0 if using_mouse else 1
	var events : Array[InputEvent] = InputMap.action_get_events(input_name)
	if events.size() > 0:
		var event_text = get_clean_name(events[event_index])
		return event_text
	return "UNBOUND"
	
func get_clean_name(event: InputEvent) -> String:
	var text = event.as_text().replace(" (Physical)", "").replace(" - Physical", "")
	if "xbox" in text.to_lower():
		for part in text.split(","):
			if "xbox" in part.to_lower():
				return part.replacen("xbox", "").replace(")", "").strip_edges()
	return text
