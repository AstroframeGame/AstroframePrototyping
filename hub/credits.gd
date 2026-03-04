extends VBoxContainer

const CREDITS = "res://hub/credits.json"

func _ready():
	var file = FileAccess.open(CREDITS, FileAccess.READ)
	var json_string = file.get_as_text()
	var data = JSON.parse_string(json_string)
	
	for key in data:
		var value = data[key]
		if value is Array:
			create_label(str(key) + ":")
			for item in value:
				create_label("  - " + str(item))
		else:
			var display_text = str(value) if key == "header" else str(key) + ": " + str(value)
			create_label(display_text)

func create_label(text_content: String):
	var label = Label.new()
	label.text = text_content
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(label)
