class_name MeleeEnemy
extends EnemyController

@export var attack_range: float = 5
@onready var player: Player = $"../PlayerSystem/Player"

func _ready() -> void:
	speed = 200

func _physics_process(delta: float) -> void:
	print(self.global_position.distance_to(player.global_position))
	if health <= 0:
		return #DEATH HERE
	if target == null && self.global_position.distance_to(player.global_position) < 250:
		target = player
	update_state()
	process_state()

func update_state():
	if target == null:
		current_state = State.IDLE
	else:
		if nav_agent.is_target_reached():
			if current_state == State.SEEKING:
				current_state = State.ATTACKING
		if current_state == State.ATTACKING && attack_done:
			current_state = State.SEEKING
		else:
			nav_agent.target_desired_distance = attack_range
			current_state = State.SEEKING
	if health <= 25:
		current_state = State.FLEEING
