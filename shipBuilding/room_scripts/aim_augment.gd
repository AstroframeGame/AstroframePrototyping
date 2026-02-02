class_name Aim_Augment
extends Augment

var enemy_target : Ship

func _ready()->void:
	super._ready()
	# for loading ship in new scene
	if ship:
		find_target_rooms(Aim_Augment, Turret)

func _process(_delta: float) -> void:
	if enemy_target and target_rooms.size()>0:
		target_rooms[0].gun.gunSprite.look_at(enemy_target.global_position)
