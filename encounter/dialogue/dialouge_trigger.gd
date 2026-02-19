extends Node
class_name DialogueTrigger

@export var dialouge = BarkGetter.retrieve("A_1_PIRATE_DESTROYER", "greeting")

#[
	#["Maera","test text"],
	#["Maera","ok"],
	#["Elisaria","test choice",["OK!",2],["No No!",3]],
	#["Maera","YEa!",-1],
	#["Elisaria","no!"]
#]

func start_dialogue()->void:
	print(get_tree().root.get_node("Hub").get_node("GameManager"))
	var gm : GameManager = get_tree().root.get_node("Hub").get_node("GameManager")
	print(gm.dialogue_runner)
	var dialouge_runner : DialougeRunner = gm.dialogue_runner
	dialouge_runner.start(dialouge)
