extends Node
class_name DialogueTrigger

@export var dialouge = [
	["Maera","test text"],
	["Maera","ok"],
	["Elisaria","test choice",["OK!",2],["No No!",3]],
	["Maera","YEa!",-1],
	["Elisaria","no!"]
]

func start_dialogue()->void:
	var dialouge_runner : DialougeRunner = GameManager.dialogue_runner
	dialouge_runner.start(dialouge)
