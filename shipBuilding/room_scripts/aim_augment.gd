class_name Aim_Augment
extends Augment

var enemy_target : Ship

func _ready()->void:
	super._ready()
	# for loading ship in new scene
	if ship:
		ship.update_occupied_cells()
		find_target_rooms(Aim_Augment, Turret)

func _process(_delta: float) -> void:
	if power_level > 1 or enemy_target == null:
		return
			
	if target_rooms.size()>0 and target_rooms[0].power_level > 0:
		target_rooms[0].gun.gunSprite.look_at(enemy_target.global_position)
		target_rooms[0].gun.shoot(5)
