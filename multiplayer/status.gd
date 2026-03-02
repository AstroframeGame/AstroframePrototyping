extends Label

var timer: float = 0.0
@onready var player: PlayerCharacter = $".."
@onready var colors = {
	"online" : Color("green"),
	"away" : Color("orange"),
	"offline" : Color("red")
}

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	timer += delta
	if player.is_multiplayer:
		var is_moving = player.input_dir != Vector2.ZERO
		if is_moving or timer < 30.0:
			text = "Online"
			add_theme_color_override("font_color", colors.online)
			if is_moving:
				timer = 0.0
		else:
			text = "Away"
			add_theme_color_override("font_color", colors.away)
	else:
		text = "Offline"
		add_theme_color_override("font_color", colors.offline)
	
		
