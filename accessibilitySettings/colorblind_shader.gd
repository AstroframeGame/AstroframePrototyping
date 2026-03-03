extends CanvasLayer
@onready var accessibility_shader: ColorRect = $AccessibilityShaderColorRect

func _ready() -> void:
	self.layer=1025

func get_color_mode() -> int:
	var color_mode =(accessibility_shader.material as ShaderMaterial).get_shader_parameter("mode") as int
	return color_mode

func set_color_mode(mode:int):
	(accessibility_shader.material as ShaderMaterial).set_shader_parameter("mode",mode)
