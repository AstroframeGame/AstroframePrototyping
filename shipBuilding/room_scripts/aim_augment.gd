class_name Aim_Augment
extends Augment

# TODO:
# account for turrets placed before [done] 
# AND after this is placed [access json?]
# aim_augment should only hold one targetRoom [done]
# face turrets toward enemy_target faster than manual control
#   target priority settings? like bloons? [closest, most health, most weapons, farthest]]
# smooth out the turret for manual control
# range?

var enemy_target : Ship

func initialize(grid:TileMapLayer) -> void:
	super.initialize(grid)
	pair_to_turret()

func _ready()->void:
	super._ready()
	pair_to_turret()

func pair_to_turret()->void:
	for neighbor in ship.find_neighbors(self):
		var check_next = false
		if target_rooms.size() == 0 and neighbor is Turret:
			for augment in neighbor.augments:
				if augment is Aim_Augment:
					check_next = true
					print("found turret with aim_augment")
					break
			if not check_next:
				# pair the turret to self
				print("augment paired to turret")
				target_rooms.append(neighbor as Turret)
				neighbor.augments.append(self as Aim_Augment)

func _process(_delta: float) -> void:
	if enemy_target and target_rooms.size()>0:
		target_rooms[0].face_toward(enemy_target)
