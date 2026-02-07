extends Node
# use the term `CursorManager` to access the singleton

# cursors from Kenney cursor pack
# https://kenney.nl/assets/crosshair-pack
# pointer from vision-cursor
# https://github.com/N3bulaX/Vision-Cursor-1

const POINTER = preload("res://shipMovement/cursors/pointer48.png")
const DENIED = preload("res://shipMovement/cursors/crosshair113.png")
const DOT = preload("res://shipMovement/cursors/crosshair001.png")
const AIM = preload("res://shipMovement/cursors/crosshair188.png")


func _ready() -> void:
	reset_cursor()

func set_cursor_aim():
	Input.set_custom_mouse_cursor(AIM)
	
func reset_cursor():
	Input.set_custom_mouse_cursor(POINTER)
