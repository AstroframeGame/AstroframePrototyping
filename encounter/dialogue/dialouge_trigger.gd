extends Node
class_name DialogueTrigger

@export var dialouge = [
	["Elisaria","Make haste, Maera, the Demon Lord is getting away!"],
	["Maera","Ok!"]
]

func _ready() -> void:
	start_dialogue()

func start_dialogue()->void:
	print(get_tree().root.get_node("Hub").get_node("GameManager"))
	var gm : GameManager = get_tree().root.get_node("Hub").get_node("GameManager")
	print(gm.dialogue_runner)
	var dialouge_runner : DialougeRunner = gm.dialogue_runner
	dialouge_runner.start(dialouge)
