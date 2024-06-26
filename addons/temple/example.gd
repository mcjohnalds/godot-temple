extends Node3D

@onready var light: DirectionalLight3D = $DirectionalLight3D


func _ready() -> void:
		light.shadow_enabled = not is_compatibility_renderer()


func is_compatibility_renderer() -> bool:
	var rendering_method: String = (
		ProjectSettings["rendering/renderer/rendering_method"]
	)
	return rendering_method == "gl_compatibility"
