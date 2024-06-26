@tool
class_name FpsController
extends RigidBody3D


@export var ground_clearance: float = 0.3:
	set(value):
		ground_clearance = value
		if not is_node_ready():
			return
		_update()


@export var height: float = 1.7:
	set(value):
		height = value
		if not is_node_ready():
			return
		_update()


@export var radius: float = 0.6:
	set(value):
		radius = value
		if not is_node_ready():
			return
		_update()


var _last_force_error: float
var _last_upright_torque_error: Vector3
var _last_yaw_torque_error: Vector3
@onready var collision_shape: CollisionShape3D = $CollisionShape
@onready var debug_capsule: MeshInstance3D = $DebugCapsule
@onready var camera: Camera3D = $Camera3D
@onready var camera_anchor: Node3D = $CameraAnchor


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	await get_tree().create_timer(0.1).timeout
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_physics_process_force_pid(delta)
	_physics_process_upright_torque_pid(delta)
	_physics_process_yaw_torque_pid(delta)
	camera.global_position = camera_anchor.global_position


func _physics_process_force_pid(delta: float) -> void:
	var query := PhysicsRayQueryParameters3D.new()
	var offset := 0.1
	query.from = global_position + Vector3(0.0, ground_clearance + offset, 0.0)
	query.to = global_position - 10.0 * Vector3(0.0, ground_clearance, 0.0)
	query.exclude = [self.get_rid()]
	var collision := get_world_3d().direct_space_state.intersect_ray(query)

	if not collision:
		return

	var point: Vector3 = collision.position
	var distance := query.from.distance_to(point) - offset
	var error := ground_clearance - distance
	var error_delta := (error - _last_force_error) / delta
	var kp := 80000.0
	var max_force := 8000.0
	var td := 0.1
	var up_force := minf(kp * (error + td * error_delta), max_force)
	if error > 0.0:
		apply_central_force(Vector3.UP * up_force)
		var input2 := Input.get_vector("move_right", "move_left", "move_backward", "move_forward")
		var friction := (
			-Vector3(linear_velocity.x, 0.0, linear_velocity.z)
			* 1600.0
		).limit_length(16000.0)
		var horiz_vel := Vector3(linear_velocity.x, 0.0, linear_velocity.z)
		if input2.length() > 0.0:
			var input3 := Vector3(input2.x, 0.0, input2.y).normalized().rotated(Vector3.UP, camera.rotation.y + TAU / 2.0)
			var perp := input3.rotated(Vector3.UP, TAU / 4.0).normalized()
			if horiz_vel.length() < 6.0:
				apply_central_force(input3 * 16000.0)
			apply_central_force(friction.project(perp))
		else:
			apply_central_force(friction)
	_last_force_error = error


func _physics_process_upright_torque_pid(delta: float) -> void:
	var target := Vector3.MODEL_TOP
	var current := global_basis.y
	var error := current.cross(target)
	var kp := 8000.0
	var td := 0.1
	var error_delta := (error - _last_upright_torque_error) / delta
	var torque := kp * (error + td * error_delta)
	apply_torque(torque)
	_last_upright_torque_error = error


func _physics_process_yaw_torque_pid(delta: float) -> void:
	var target := -Vector3(camera.global_basis.z.x, 0.0, camera.global_basis.z.z).normalized()
	var current := Vector3(global_basis.z.x, 0.0, global_basis.z.z).normalized()
	var error := current.cross(target)
	var kp := 8000.0
	var td := 0.1
	var error_delta := (error - _last_yaw_torque_error) / delta
	var torque := kp * (error + td * error_delta)
	apply_torque(torque)
	_last_yaw_torque_error = error


func _input(event: InputEvent) -> void:
	var motion := event as InputEventMouseMotion 
	if motion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		var mouse_sensitivity := 0.002
		var m := 0.9 * TAU / 4.0
		var rx := camera.rotation.x - motion.relative.y * mouse_sensitivity
		var ry := camera.rotation.y - motion.relative.x * mouse_sensitivity
		camera.rotation.x = clamp(rx, -m, m)
		camera.rotation.y = ry


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()
	if event.is_action_pressed("action"):
		get_viewport().get_camera_3d().current = false
	if (
		event is InputEventMouseButton
		and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE
	):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _update() -> void:
	var capsule: CapsuleShape3D = collision_shape.shape
	capsule.radius = radius
	capsule.height = height - ground_clearance
	collision_shape.position = Vector3(
		0.0, ground_clearance + capsule.height / 2.0, 0.0
	)
	debug_capsule.position = collision_shape.position
	var capsule_mesh: CapsuleMesh = debug_capsule.mesh
	capsule_mesh.radius = radius
	capsule_mesh.height = capsule.height
	debug_capsule.position = collision_shape.position
