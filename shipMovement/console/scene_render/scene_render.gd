extends Node2D

@onready var sub_viewport: SubViewport = $SubViewport

func _ready() -> void:
	await get_tree().process_frame
	capture_img()

func capture_img():
	sub_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	await RenderingServer.frame_post_draw
	
	var image = sub_viewport.get_texture().get_image()
	var filename = "output.png"
	if sub_viewport.get_child_count() > 0:
		filename = sub_viewport.get_child(0).name + ".png"
	
	var path = "res://shipMovement/console/scene_render/output/" + filename
	image.save_png(path)
	print("Image saved to " + path)
