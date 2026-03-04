extends MultiplayerSpawner

@onready var game_manager: GameManager = $".."

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	game_manager.game_start.connect(_set_path)
	
func _set_path(scene: Node2D):
	spawn_path = scene.get_path()
