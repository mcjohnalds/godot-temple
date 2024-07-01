class_name Global
extends Node3D


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _input(event: InputEvent) -> void:
	if OS.is_debug_build() and event.is_action_pressed("quit"):
		get_tree().quit()
	if event.is_action_pressed("change_mouse_input"):
		match Input.get_mouse_mode():
			Input.MOUSE_MODE_CAPTURED:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			Input.MOUSE_MODE_VISIBLE:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _unhandled_input(event: InputEvent) -> void:
	if OS.is_debug_build():
		var e := event as InputEventMouseButton
		if e and e.button_index == MOUSE_BUTTON_LEFT && e.pressed:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
