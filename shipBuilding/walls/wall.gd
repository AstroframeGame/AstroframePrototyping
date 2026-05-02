extends CollisionShape2D
class_name Wall

enum WallType { EXT_WALL_ONLY, EXT_DOOR_ONLY, WALL, DOOR }

@export var wall_type: WallType = WallType.WALL

func is_ext() -> bool:
	return wall_type == WallType.EXT_WALL_ONLY or wall_type == WallType.EXT_DOOR_ONLY

func is_door() -> bool:
	return wall_type == WallType.EXT_DOOR_ONLY or wall_type == WallType.DOOR

func _ready() -> void:
	$Sprite2D.modulate = Color.GREEN if (wall_type == WallType.DOOR or wall_type == WallType.EXT_DOOR_ONLY) else Color.WHITE

func on_wall_refresh():
	if is_door():
		disabled = true
		visible = false
