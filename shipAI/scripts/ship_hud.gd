extends CanvasLayer
class_name ShipHud

var ship : Ship:
	get:
		return get_parent()

@onready var healthbar : TextureProgressBar = $HPBar
@onready var health_label : Label = $HPBar/Label

# @Kevin change to ready?
func initialize() -> void:
	healthbar = $HPBar
	health_label = $HPBar/Label
	healthbar.max_value = ship.max_hit_points
	health_label.text = str(ship.max_hit_points)
	update_hp_bar()
	ship.on_airlock_interaction.connect(toggle_hud, ConnectFlags.CONNECT_DEFERRED)

func toggle_hud(_interactor, is_inside : bool):
	visible = is_inside
		
func update_hp_bar():
	healthbar.value = ship.hit_points
	health_label.text = str(ship.hit_points)

	
