extends StaticBody2D

var start_pos: Vector2
var velocity: Vector2
var movement_radius: Vector2

var start_rot: float
var rotation_velocity: float
var rotation_limit: float

const HIT_SHIP_VFX_PREFAB = preload("res://art/vfx/hit_ship_vfx.tscn")

signal on_hit()
@export var _hit_points : int = 40
var hit_points : int:
	get:
		return _hit_points
	set(value):
		if value < _hit_points:
			on_hit.emit()
		_hit_points = value

func _ready() -> void:
	on_hit.connect(death_check)

func death_check():
	if hit_points > 0:
		return
	queue_free.call_deferred()

func take_damage(amount:int, pos_ws : Vector2):
	hit_points -= amount # property has callback that sets the hud to update
	hit_vfx(pos_ws)

func hit_vfx(pos : Vector2):
	var g = HIT_SHIP_VFX_PREFAB.instantiate()
	g.global_position = pos
	for c in g.get_children():
		if c is GPUParticles2D:
			c.restart()
	ProjectileManager.add_child(g)
