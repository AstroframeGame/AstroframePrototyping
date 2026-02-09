extends Node
class_name Faction

var relationship: Dictionary = {
	"fear": 0,
	"trust": 0,
	"respect": 0,
	"goodwill": 0
}

func update_relationship(key: String, amount) -> void:
	relationship[key] += amount
