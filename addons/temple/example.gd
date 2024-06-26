extends Node3D

@onready var light: DirectionalLight3D = $DirectionalLight3D
@onready var camera: Camera3D = $Camera3D
@onready var fps_controller: FpsController = $FpsController


func _ready() -> void:
	light.shadow_enabled = not is_compatibility_renderer()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _process(_delta: float) -> void:
	camera.look_at(fps_controller.global_position)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()
	if event.is_action_pressed("action"):
		get_viewport().get_camera_3d().current = false
	if event.is_action_pressed("slap"):
		fps_controller.apply_torque_impulse(Vector3.ONE * 200.0)
	if (
		event is InputEventMouseButton
		and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE
	):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func is_compatibility_renderer() -> bool:
	var rendering_method: String = (
		ProjectSettings["rendering/renderer/rendering_method"]
	)
	return rendering_method == "gl_compatibility"
