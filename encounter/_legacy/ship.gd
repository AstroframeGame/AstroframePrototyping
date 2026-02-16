extends CharacterBody2D
class_name TestShip

@export var sector_a: Area2D
@export var sector_b: Area2D
@export var npc_ship: TestShip
@export var player_ship: TestShip

var current_sector: Area2D = null

# systems
var shields: int
var engines: int
var weapons: int

func _ready() -> void:
	pass	

func check_proximity(shipA: TestShip, shipB: TestShip) -> float:
	if not shipA or not shipB:
		return -1
	
	return shipA.global_position.distance_to(shipB.global_position)
	
func sector_entered(_body: TestShip) -> void:
	pass

func _on_sector_entered(body: TestShip, sector: Area2D) -> void:
	if body == self:
		current_sector = sector
	else:
		if(sector == current_sector):
			print("[%s]: %s entered %s's current sector" % 
				[self.name.to_upper(), body.name, self.name])
				
			self.sector_entered(body)

# attack another ship
func launch_attack(body: TestShip, system: String, strength: int) -> void:
	print("[%s]: attacking %s's %s system" % 
		[self.name.to_upper(), body.name, system])
		
	body.system_damage(system, strength)

# get attacked
func system_damage(system: String, strength: int) -> void:
	if self[system] > 0:
		print("[%s]: %s system attacked (-%d) --> %d" % 
			[self.name.to_upper(), system, strength, self[system]])
	
	self[system] -= strength
	if self[system] <= 0:
		self[system] = 0
		print("[%s]: %s system destroyed!" %
			[self.name.to_upper(), system])

	update_label(system)

# fix systems
func system_repair(system: String, strength: int) -> void:
	if self[system] < 10:
		print("[%s]: %s system repaired (+%d) --> %d" % 
			[self.name.to_upper(), system, strength, self[system]])
	
	self[system] += strength
	if self[system] >= 10:
		self[system] = 10
		print("[%s]: %s system at full health!" %
			[self.name.to_upper(), system])
		
	update_label(system)

func update_label(args):
	pass
