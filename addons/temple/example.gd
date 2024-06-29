extends Node3D

@onready var light: DirectionalLight3D = $DirectionalLight3D
@onready var camera: Camera3D = $Camera3D
@onready var fps_controller: FpsControllerV3 = $FpsControllerV3


func _ready() -> void:
	light.shadow_enabled = not is_compatibility_renderer()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _process(delta: float) -> void:
	var current := -camera.global_basis.z
	var target := camera.global_position.direction_to(fps_controller.global_position)
	var	new_dir := current.slerp(target, minf(delta * 5.0, 1.0))
	camera.look_at(camera.global_position + new_dir)
	# for b in [fps_controller.body, fps_controller.head, fps_controller.roller]:
		# b.apply_central_force(Vector3.UP * 9.8 * b.mass * 2.0)
		# b.apply_torque(Vector3(0.005, 0.003, 0.0))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()
	if event.is_action_pressed("action"):
		get_viewport().get_camera_3d().current = false
	if event.is_action_pressed("slap"):
		fps_controller.apply_central_impulse((Vector3.BACK * 0.1 + Vector3.LEFT * 0.1 + Vector3.UP * 1.8) * 20.5)
		fps_controller.apply_torque_impulse((Vector3.UP * 0.1 + Vector3.RIGHT * 0.1) * 1.0)
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
