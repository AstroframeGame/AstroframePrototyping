extends Node

@export var dialouge = [
	["Elisaria","Make haste, Maera, the Demon Lord is getting away!"],
	["Maera","Ok!"]
]

func start_dialogue()->void:
	var dialouge_runner : DialougeRunner = get_tree().root.get_node("GameManager").dialouge_runner
	dialouge_runner.start(dialouge)
