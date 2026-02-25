class_name RemappableButton
extends Button

@export var action_name: String
@export var event_index: int = 0
@export var is_keyboard_bind: bool = true

const CONTROLLER_LABELS: Dictionary = {
	JoyButton.JOY_BUTTON_A: "A",
	JoyButton.JOY_BUTTON_B: "B",
	JoyButton.JOY_BUTTON_X: "X",
	JoyButton.JOY_BUTTON_Y: "Y",
	JoyButton.JOY_BUTTON_LEFT_SHOULDER: "LB",
	JoyButton.JOY_BUTTON_RIGHT_SHOULDER: "RB",
	JoyButton.JOY_BUTTON_LEFT_STICK: "L3",
	JoyButton.JOY_BUTTON_RIGHT_STICK: "R3",
	JoyButton.JOY_BUTTON_DPAD_UP: "↑",
	JoyButton.JOY_BUTTON_DPAD_DOWN: "↓",
	JoyButton.JOY_BUTTON_DPAD_LEFT: "←",
	JoyButton.JOY_BUTTON_DPAD_RIGHT: "→",
	JoyButton.JOY_BUTTON_START: "Start",
	JoyButton.JOY_BUTTON_GUIDE: "Select"
}

func _ready() -> void:
	toggle_mode = true
	toggled.connect(_toggled)
	_toggled(false)
	
func _toggled(toggled_on: bool) -> void:
	print("Toggled:", toggled_on)
	if !action_name or !InputMap.has_action(action_name):
		return
		
	if toggled_on:
		text = "Press New Input..."
		return
	
	if event_index >= InputMap.action_get_events(action_name).size():
		text = "No Binding"
		return
		
	var input = InputMap.action_get_events(action_name)[event_index]
	if input is InputEventJoypadButton and !is_keyboard_bind:
		if CONTROLLER_LABELS.has(input.button_index):
			text = CONTROLLER_LABELS.get(input.button_index)
		else:
			text = "New Button " + str(input.button_index)
	
	elif input is InputEventKey and is_keyboard_bind:
		if input.physical_keycode != 0:
			text = OS.get_keycode_string(input.physical_keycode)
		else:
			text = OS.get_keycode_string(input.keycode)

func _unhandled_input(event: InputEvent) -> void:
	if !InputMap.has_action(action_name) or !is_pressed():
		return
		
	if event.is_pressed() and (event is InputEventKey or event is InputEventJoypadButton):
		var events_list = InputMap.action_get_events(action_name)
		if event_index < events_list.size():
			InputMap.action_erase_event(action_name, events_list[event_index])
			
		InputMap.action_add_event(action_name, event)
		event_index = InputMap.action_get_events(action_name).size()-1
		button_pressed = false
		release_focus()
