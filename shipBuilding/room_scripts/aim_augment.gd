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
	var chosen_turret : Turret
	if power_level < 2 or enemy_target == null:
		return
	if enemy_target.get_total_room_count()<=1:
		return
	
	# get first turret in list
	for r in target_rooms:
		if r is Turret:
			if r.power_level > 0:
				chosen_turret = r
				break

	if chosen_turret:
		chosen_turret.gun.gunSprite.look_at(enemy_target.global_position)
		chosen_turret.gun.shoot(10)
		
