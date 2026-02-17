class_name EnemyController
extends CharacterBody2D

enum State {IDLE, SEEKING, ATTACKING, FLEEING}
@export var speed : float
@export var current_state : State = State.IDLE
@export var target = null
@export var health : float = 100
@export var time_since_heal : float = 0
@export var attack_cooldown : float = 2
@export var attack_done: bool = false
@export var attack_damage: float = 10

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D

func _physics_process(delta: float) -> void:
	pass

func takeDamage(damage : int):
	health -= damage
	print("Damage Taken! Enemy now at %s health" % health)

func process_state():
	match current_state:
		State.IDLE:
			sit_idle()
		State.SEEKING:
			seek_target()
		State.ATTACKING:
			attack()
		State.FLEEING:
			flee()

func sit_idle():
	print("enemy idling")

func seek_target():
	print("enemy seeking")
	nav_agent.velocity = self.global_position.direction_to(nav_agent.get_next_path_position())
	nav_agent.target_position = target.global_position

func attack():
	print("enemy attacking")
	speed *= 2
	nav_agent.target_desired_distance = 50
	if nav_agent.is_target_reached():
		if target.has_method("takeDamage"):
			target.takeDamage(attack_damage)
		attack_done = true
		speed /= 4
		nav_agent.target_desired_distance = 5
		await get_tree().create_timer(attack_cooldown).timeout
		speed *= 2

func flee():
	print("enemy fleeing")


func _on_navigation_agent_2d_velocity_computed(safe_velocity: Vector2) -> void:
	velocity = velocity.move_toward(safe_velocity * speed, 10)
	move_and_slide()
