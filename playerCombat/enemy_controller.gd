extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -400.0
var health = 100
var timeSinceHeal = 0

func take_damage(damage : int, _vfx_pos:Vector2):
	health -= damage
	#print("Damage Taken! Enemy now at %s health" % health)
	
