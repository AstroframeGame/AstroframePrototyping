extends Control
class_name DialougeRunner

const DIALOUGE_END = -1


@export var dialouge = [
	["Maera","test text"],
	["Elisaria","test choice",["OK!",2],["No No!",3]],
	["Maera","YEa!",-1],
	["Elisaria","no!"]
]

var index = -1
var done :
	get :
		return char_index == dialouge[index][1].length()
var char_index = 0

func eval_next(option=0):
	# evaluate next index
	var next_index = DIALOUGE_END
	if index+1 >= dialouge.size():
		# end
		next_index = DIALOUGE_END
	elif dialouge[index].size() < 3:
		# next
		next_index = index + 1
	elif dialouge[index].size() < 4:
		# parameter of next
		next_index = dialouge[index][2]
	else:
		# choices
		next_index = dialouge[index][option+2][1]
	
	print(dialouge[index], dialouge.size(), " ",next_index)
	index = next_index
	if index == DIALOUGE_END:
		end()
	else:
		name_label.text = dialouge[index][0]
		text.text = ""
		char_index = 0
		$Timer.start()

@onready var text: RichTextLabel = $Background/TextLabel
@onready var name_label: RichTextLabel = $Background/NameLabel

func _on_timer_timeout() -> void:
	text.text += dialouge[index][1][char_index]
	char_index += 1
	if done:
		$Timer.stop()

func proceed():
	print("Dialouge : Proceed")
	if done:
		eval_next()
	else:
		$Timer.stop()
		text.text = dialouge[index][1]
		char_index = dialouge[index][1].length()

func start(new_dialouge):
	dialouge = new_dialouge
	visible = true
	index = -1
	
	eval_next()
	
func end():
	visible = false

func _input(_event: InputEvent) -> void:
	if visible == false:
		return
	if Input.is_action_just_pressed("dialouge_next"):
		proceed()
	#elif Input.is_action_just_pressed("dialouge_negative"):
		#pass

func _ready() -> void:
	$Timer.timeout.connect(_on_timer_timeout)
	visible = false
