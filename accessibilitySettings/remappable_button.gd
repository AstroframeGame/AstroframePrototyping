class_name RemappableButton
extends Button

@export var action_name: String
@export var event_index: int = 0
@export var action_type: String

var menu_manager : MenuManager:
	get:
		return get_node("/root/Hub/UI")

const CONTROLLER_LABELS: Dictionary = {
	JoyButton.JOY_BUTTON_A: "A",
	JoyButton.JOY_BUTTON_B: "B",
	JoyButton.JOY_BUTTON_X: "X",
	JoyButton.JOY_BUTTON_Y: "Y",
	JoyButton.JOY_BUTTON_BACK: "Back",
	JoyButton.JOY_BUTTON_GUIDE: "Select",
	JoyButton.JOY_BUTTON_START: "Start",
	JoyButton.JOY_BUTTON_LEFT_STICK: "L-Stick Press",
	JoyButton.JOY_BUTTON_RIGHT_STICK: "R-Stick Press",
	JoyButton.JOY_BUTTON_LEFT_SHOULDER: "LB",
	JoyButton.JOY_BUTTON_RIGHT_SHOULDER: "RB",
	JoyButton.JOY_BUTTON_DPAD_UP: "D-Pad ↑",
	JoyButton.JOY_BUTTON_DPAD_DOWN: "D-Pad ↓",
	JoyButton.JOY_BUTTON_DPAD_LEFT: "D-Pad ←",
	JoyButton.JOY_BUTTON_DPAD_RIGHT: "D-Pad →",
}

const MOTION_LABELS: Dictionary = {
	JoyAxis.JOY_AXIS_LEFT_X: "L-Stick ←→",
	JoyAxis.JOY_AXIS_LEFT_Y: "L-Stick ↑↓",
	JoyAxis.JOY_AXIS_RIGHT_X: "R-Stick ←→",
	JoyAxis.JOY_AXIS_RIGHT_Y: "R-Stick ↑↓",
	JoyAxis.JOY_AXIS_TRIGGER_LEFT: "LT",
	JoyAxis.JOY_AXIS_TRIGGER_RIGHT: "RT"
}

func _ready() -> void:
	toggle_mode = true
	toggled.connect(_toggled)
	_toggled(false)
	
func _toggled(toggled_on: bool) -> void:
	if !action_name or !InputMap.has_action(action_name):
		return
		
	if toggled_on:
		text = "Press New Input..."
		return
	
	if event_index >= InputMap.action_get_events(action_name).size():
		text = "No Binding"
		return
		
	var input = InputMap.action_get_events(action_name)[event_index]
	if input is InputEventJoypadButton && action_type == "contr":
		if CONTROLLER_LABELS.has(input.button_index):
			text = CONTROLLER_LABELS.get(input.button_index)
		else:
			text = "New Button " + str(input.button_index)
		action_type = "contr"
	
	elif input is InputEventJoypadMotion && action_type == "contr":
		if MOTION_LABELS.has(input.axis):
			text = MOTION_LABELS.get(input.axis)
		else:
			text = "New Button " + str(input.axis)
		action_type = "contr"
	
	elif input is InputEventKey && action_type == "keyBrd":
		if input.physical_keycode != 0:
			text = OS.get_keycode_string(input.physical_keycode)
		else:
			text = OS.get_keycode_string(input.keycode)
		action_type = "keyBrd"


func _unhandled_input(event: InputEvent) -> void:
	if !InputMap.has_action(action_name) or !is_pressed():
		return
		
	if event.is_pressed() and (event is InputEventKey or event is InputEventJoypadButton or event is InputEventJoypadMotion) and (((event is InputEventJoypadButton or event is InputEventJoypadMotion) and action_type == "contr") or (event is InputEventKey and action_type == "keyBrd")):
		if event.is_action("pause"):
			button_pressed = false
			release_focus()
			# baaad solution
			# "pause" here clashes with "pause" when trying to exit settings
			await get_tree().process_frame 
			menu_manager.open_menu("Settings")
			return
		
		var events_list = InputMap.action_get_events(action_name)
		if event_index < events_list.size():
			InputMap.action_erase_event(action_name, events_list[event_index])
			
		InputMap.action_add_event(action_name, event)
		event_index = InputMap.action_get_events(action_name).size()-1
		button_pressed = false
		grab_focus()
