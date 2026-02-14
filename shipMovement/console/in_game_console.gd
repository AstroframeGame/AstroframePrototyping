extends CanvasLayer

@onready var v_box: VBoxContainer = $VBoxContainer

func log_message(text: String):
	print(text)
	var label = Label.new()
	label.text = text
	label.modulate.a = 0
	v_box.add_child(label)
	
	var tween = create_tween()
	tween.tween_property(label, "modulate:a", 1.0, 0.5)
	tween.tween_interval(2.0)
	tween.tween_property(label, "modulate:a", 0.0, 0.5)
	tween.tween_callback(label.queue_free)
