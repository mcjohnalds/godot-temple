extends Node3D
class_name Global


func _ready() -> void:
	if OS.is_debug_build():
		# get_window().content_scale_factor = 2.0
		get_window().mode = Window.MODE_WINDOWED
		get_window().size *= 2


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("quit"):
		get_tree().quit()
