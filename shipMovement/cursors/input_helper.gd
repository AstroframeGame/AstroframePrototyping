extends Node

var using_mouse: bool = true

var move: Vector2:
	get:
		return Input.get_vector("left", "right", "up", "down")

var look: Vector2:
	get:
		return _look_delta

var controller_look : Vector2:
	get:
		return Input.get_vector("ship_look_left", "ship_look_right", "ship_look_up", "ship_look_down")

var mouse_center_offset : Vector2 :
	get:
		var center = get_viewport().get_visible_rect().get_center()
		return get_viewport().get_mouse_position() - center

func mouse_center_offset_deadzone(deadzone : float) -> Vector2:
	var look_dir = mouse_center_offset
	if look_dir.abs().x < deadzone:
		look_dir = Vector2.ZERO
	else:
		look_dir.x -= deadzone * sign(look_dir.x) 
	print(look_dir)
	return look_dir

var _look_delta: Vector2 = Vector2.ZERO

func _ready() -> void:
	_update_cursor_visibility()

func _input(event: InputEvent) -> void:
	var prev_mode = using_mouse
	
	if event is InputEventMouseMotion:
		using_mouse = true
		_look_delta = event.relative
	elif event is InputEventMouseButton:
		using_mouse = true
	elif event is InputEventJoypadButton or event is InputEventJoypadMotion:
		if event is InputEventJoypadMotion and abs(event.axis_value) < 0.2:
			return
		using_mouse = false
		
	if prev_mode != using_mouse:
		_update_cursor_visibility()

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
