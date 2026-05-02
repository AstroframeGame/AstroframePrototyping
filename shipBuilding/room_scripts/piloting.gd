class_name Piloting
extends Room

@onready var seat: SeatInteractable = $SeatHex
@onready var firing := false
var AccelCurve : Curve = load("res://shipBuilding/prefabs/accelcurve.tres");
var brakingCurve : Curve = load("res://shipBuilding/prefabs/brakingcurve.tres")
@export var timeToAccelerate : float = 2;
@export var timeToBrake : float = 2;
var newTimeToBrake : float = 0;
@export var turnSpeed : float = 2;

# this method is searched by name from the player
func handle_input(event:InputEvent):
	if ship.ship_mode == ship.SHIP_MODE.COMBAT:
		# autofire
		if event.is_action_pressed("ship_fire"):
			firing = true
			# cannons wont autofire
			shoot_all_cannons()
		if event.is_action_released("ship_fire"):
			firing = false
		# swivel cannons autofire
		for swivel : SwivelCannon in ship.get_swivel_guns():
			swivel.handle_input(event)
			swivel.firing = firing
			
	elif ship.ship_mode == ship.SHIP_MODE.EDITING:
		firing = false
		
func shoot_all_cannons():
	for child in ship.get_children():
		if child is Cannon:
			child.shoot()

func is_active() -> bool:
	return seat.controlled_by != null

var timeAccelerateHeld = 0;
var timeLetGo = 0;

var timePressed = 0;
var timeReleased = 0;
var goalState = 0;
var currentSpeed = 0;

func get_velocity(state : PhysicsDirectBodyState2D) -> Vector2:
	
	var engines = ship.get_engines()
	
	if engines.power_level==0:
		engines.blink_red()
		return Vector2.ZERO
	
	var velocity = Vector2.ZERO
	
	
	var direction = Input.get_axis("down","up");
	var turn = Input.get_axis("left","right");
	#if we're going from 0 -> direction, we want to use the acceleration
	var speed = 0;
	
	if goalState == 0 && direction:
		goalState = direction;
	if goalState:
		#print(direction);
		if direction == goalState:
			timeReleased = 0;
			timePressed += state.step;
			timePressed = min(timePressed,timeToAccelerate);
			speed = AccelCurve.sample(timePressed/timeToAccelerate) * engines.get_max_speed()/20;
			ship.rotate(turn * 0.01 * timePressed/timeToAccelerate)
			currentSpeed = speed;
			#print(currentSpeed)
			newTimeToBrake = currentSpeed * 20/engines.get_max_speed() * timeToBrake
		else:
			if direction:
				timePressed = 0;
				timeReleased += state.step * 2
			else:
				timePressed -= state.step;
				timeReleased += state.step
			ship.rotate(turn * 0.01 * (1 - timeReleased/newTimeToBrake)); #need to center ship to make this correct;
			timePressed = max(timePressed,0);
			timeReleased = min(timeReleased,newTimeToBrake);
			speed = brakingCurve.sample(timeReleased/newTimeToBrake) * currentSpeed;
			#print(speed)
			if speed == 0:
				goalState = 0;
	
	velocity = goalState * speed * Vector2(0,-1).rotated(ship.global_rotation);
	
	return velocity
